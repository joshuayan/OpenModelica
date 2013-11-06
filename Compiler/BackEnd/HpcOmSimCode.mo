/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package HpcOmSimCode
" file:        HpcOmSimCode.mo
  package:     HpcOmSimCode
  description: HpcOmSimCode contains the logic to create a parallelized simcode.

  RCS: $Id: HpcOmSimCode.mo 15486 2013-05-24 11:12:35Z marcusw $
"
// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTableExpToIndex;
public import SimCode;

// protected imports
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDAETransform;
protected import BackendVariable;
protected import BackendVarTransform;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import Flags;
protected import GlobalScript;
protected import HpcOmScheduler;
protected import HpcOmTaskGraph;
protected import List;
protected import Matching;
protected import SimCodeUtil;
protected import System;
protected import Util;

public function createSimCode "function createSimCode
  entry point to create SimCode from BackendDAE."
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode simCode;
algorithm
  simCode := matchcontinue (inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args)
    local
      String fileDir, cname;
      Integer lastEqMappingIdx, maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;
      Integer numberofLinearSys, numberofNonLinearSys, numberofMixedSys;
      BackendDAE.BackendDAE dlow, dlow2;
      Option<BackendDAE.BackendDAE> initDAE;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      Absyn.Path class_;
      
      // new variables
      SimCode.ModelInfo modelInfo;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;         // --> functionODE
      list<list<SimCode.SimEqSystem>> algebraicEquations;   // --> functionAlgebraics
      list<SimCode.SimEqSystem> residuals;                  // --> initial_residual
      Boolean useSymbolicInitialization;                    // true if a system to solve the initial problem symbolically is generated, otherwise false
      Boolean useHomotopy;                                  // true if homotopy(...) is used during initialization
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;

      list<SimCode.JacobianMatrix> LinearMatrices, SymbolicJacs, SymbolicJacsTemp, SymbolicJacsStateSelect;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      list<DAE.Constraint> constrsarr;
      list<DAE.ClassAttributes> clsattrsarra;

      list<DAE.Exp> lits;
      list<SimCode.SimVar> tempvars;
      
      SimCode.JacobianMatrix jacG;
      Integer highestSccIdx, compCountPlusDummy;
      Option<BackendDAE.BackendDAE> inlineDAE;
      list<SimCode.StateSet> stateSets;
      array<Integer> systemIndexMap;
      list<tuple<Integer,Integer>> equationSccMapping, equationSccMapping1; //Maps each simEq to the scc
      array<list<Integer>> sccSimEqMapping; //Maps each scc to a list of simEqs
      array<Integer> simEqSccMapping; //Maps each simEq to the scc
      BackendDAE.SampleLookup sampleLookup;
      BackendDAE.StrongComponents allComps;
      
      HpcOmTaskGraph.TaskGraph taskGraph;  
      HpcOmTaskGraph.TaskGraph taskGraphOde;
      HpcOmTaskGraph.TaskGraph taskGraph1;  
      HpcOmTaskGraph.TaskGraphMeta taskGraphData;
      HpcOmTaskGraph.TaskGraphMeta taskGraphDataOde;
      String fileName, fileNamePrefix;
      HpcOmTaskGraph.TaskGraphMeta taskGraphData1;
      list<list<Integer>> parallelSets;
      list<list<Integer>> criticalPaths, criticalPathsWoC;
      Real cpCosts, cpCostsWoC;
      
      //Additional informations to append SimCode
      list<DAE.Exp> simCodeLiterals;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      list<SimCode.SimEqSystem> residualEquations;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      list<SimCode.RecordDeclaration> simCodeRecordDecls;
      list<String> simCodeExternalFunctionIncludes;
      
      Boolean taskGraphMetaValid;
      String taskGraphMetaMessage, criticalPathInfo;
      array<tuple<Integer,Integer>> schedulerInfo;
      HpcOmScheduler.Schedule schedule;
      HpcOmScheduler.ScheduleSimCode taskScheduleSimCode;
      
      Integer graphOps;
      Real graphCosts;
      
    case (_, _, _, _, _, _, _, _, _, _, _, _) equation
      uniqueEqIndex = 1;
    
      //Setup
      //-----
      System.realtimeTick(GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);  
      (simCode,(lastEqMappingIdx,equationSccMapping)) = SimCodeUtil.createSimCode(inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args);
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      highestSccIdx = findHighestSccIdxInMapping(equationSccMapping,-1);
      compCountPlusDummy = listLength(allComps)+1;
      equationSccMapping1 = removeDummyStateFromMapping(equationSccMapping);
      //the mapping can contain a dummy state as first scc
      equationSccMapping = Util.if_(intEq(highestSccIdx, compCountPlusDummy), equationSccMapping1, equationSccMapping);
      
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));
      simEqSccMapping = convertToSimEqSccMapping(equationSccMapping, lastEqMappingIdx);
      Debug.execStat("hpcom setup", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);      

      //Create TaskGraph
      //----------------
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE,filenamePrefix);
      
      Debug.execStat("hpcom createTaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);  
      fileName = ("taskGraph"+&filenamePrefix+&".graphml"); 
      schedulerInfo = arrayCreate(arrayLength(taskGraph), (-1,-1));   
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph, taskGraphData, fileName, "", {}, {}, sccSimEqMapping ,schedulerInfo);
      Debug.execStat("hpcom dumpTaskGraph", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES); 

      //Create Costs
      //------------
      taskGraphData = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix +& "_eqs_prof.xml" , simEqSccMapping, taskGraphData); 
      Debug.execStat("hpcom create costs", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      
      //Get ODE System
      //--------------
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE,filenamePrefix);
      Debug.execStat("hpcom get ode system", GlobalScript.RT_CLOCK_EXECSTAT_HPCOM_MODULES);
      
      taskGraphMetaValid = HpcOmTaskGraph.validateTaskGraphMeta(taskGraphDataOde, inBackendDAE);
      taskGraphMetaMessage = Util.if_(taskGraphMetaValid, "TaskgraphMeta valid\n", "TaskgraphMeta invalid\n");
      print(taskGraphMetaMessage);
      
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde); 
      
      //Assign levels and get critcal path
      //----------------------------------
      ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC),parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraphOde,taskGraphDataOde);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      ((graphOps,graphCosts)) = HpcOmTaskGraph.sumUpExecCosts(taskGraphDataOde);
      criticalPathInfo = criticalPathInfo +& " sum: (" +& realString(graphCosts) +& " ; " +& intString(graphOps) +& ")";
      fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");  
      schedulerInfo = arrayCreate(arrayLength(taskGraphOde), (-1,-1));
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPathsWoC)), sccSimEqMapping, schedulerInfo);  

      //Apply filters
      //-------------
      (taskGraph1,taskGraphData1) = applyFiltersToGraph(taskGraphOde,taskGraphDataOde,inBackendDAE,true);
      //HpcOmTaskGraph.printTaskGraph(taskGraph1);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData1); 
      
      //Create schedule
      //---------------
      schedule = createSchedule(taskGraph1,taskGraphData1,sccSimEqMapping,filenamePrefix);
      taskScheduleSimCode = HpcOmScheduler.convertScheduleToSimCodeSchedule(schedule);
      
      fileName = ("taskGraph"+&filenamePrefix+&"ODE_schedule.graphml");  
      schedulerInfo = HpcOmScheduler.convertScheduleStrucToInfo(schedule,arrayLength(taskGraph));      

      ((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC),parallelSets) = HpcOmTaskGraph.longestPathMethod(taskGraph1,taskGraphData1);
      criticalPathInfo = HpcOmTaskGraph.dumpCriticalPathInfo((criticalPaths,cpCosts),(criticalPathsWoC,cpCostsWoC));
      //criticalPathInfo = "";
      //criticalPaths = {{}};
      //criticalPathsWoC = {{}};
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphData1, fileName, criticalPathInfo, HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPaths)), HpcOmTaskGraph.convertNodeListToEdgeTuples(List.first(criticalPathsWoC)), sccSimEqMapping, schedulerInfo);
      //HpcOmScheduler.printSchedule(taskSchedule);
      
      //print("Parallel informations:\n");
      //printParInformation(hpcOmParInformation);
      
      SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, _) = simCode;

      checkOdeSystemSize(taskGraphOde,odeEquations);

      simCode = SimCode.SIMCODE(modelInfo, simCodeLiterals, simCodeRecordDecls, simCodeExternalFunctionIncludes, allEquations, odeEquations, algebraicEquations, residualEquations, useSymbolicInitialization, useHomotopy, initialEquations, startValueEquations, 
                 parameterEquations, inlineEquations, removedEquations, algorithmAndEquationAsserts, stateSets, constraints, classAttributes, zeroCrossings, relations, sampleLookup, whenClauses, 
                 discreteModelVars, extObjInfo, makefileParams, delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, crefToSimVarHT, SOME(taskScheduleSimCode));
      
      print("HpcOm is still under construction.\n");
      then simCode;
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/HpcOmSimCode.mo: function createSimCode failed."});
    then fail();
  end matchcontinue;
end createSimCode;

protected function applyFiltersToGraph
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input BackendDAE.BackendDAE inBackendDAE;
  input Boolean iApplyFilters;
  output HpcOmTaskGraph.TaskGraph oTaskGraph;  
  output HpcOmTaskGraph.TaskGraphMeta oTaskGraphMeta;
protected
  String flagValue;
  Boolean changed1,changed2;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
  
  array<list<Integer>> sccSimEqMapping;
  BackendDAE.StrongComponents allComps;
  array<tuple<Integer,Integer>> schedulerInfo;
algorithm
  (oTaskGraph,oTaskGraphMeta) := matchcontinue(iTaskGraph,iTaskGraphMeta,inBackendDAE,iApplyFilters)
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
      then (iTaskGraph, iTaskGraphMeta);
    case(_,_,_,true)
      equation
        //print("Start merging\n");
        //Merge simple and parent nodes
        taskGraph1 = arrayCopy(iTaskGraph);
        taskGraphMeta1 = HpcOmTaskGraph.copyTaskGraphMeta(iTaskGraphMeta);
        (taskGraph1,taskGraphMeta1,changed1) = HpcOmTaskGraph.mergeSimpleNodes(taskGraph1,taskGraphMeta1,inBackendDAE);
        
        //(allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
        //sccSimEqMapping = arrayCreate(listLength(allComps), {});
        //schedulerInfo = arrayCreate(arrayLength(taskGraph1), (-1,-1));
        //print("MergeParentNodes\n");
        //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph1, taskGraphMeta1, "testgraph.graphml", "", {}, {}, sccSimEqMapping, schedulerInfo);
        (taskGraph1,taskGraphMeta1,changed2) = HpcOmTaskGraph.mergeParentNodes(taskGraph1, taskGraphMeta1);
        (taskGraph1,taskGraphMeta1) = applyFiltersToGraph(taskGraph1,taskGraphMeta1,inBackendDAE,changed1 or changed2);
      then (taskGraph1,taskGraphMeta1);
    else then (iTaskGraph, iTaskGraphMeta);
  end matchcontinue;
end applyFiltersToGraph;

protected function createSchedule
  input HpcOmTaskGraph.TaskGraph iTaskGraph;  
  input HpcOmTaskGraph.TaskGraphMeta iTaskGraphMeta;
  input array<list<Integer>> iSccSimEqMapping;
  input String iFilenamePrefix;
  output HpcOmScheduler.Schedule oSchedule;
protected
  String flagValue;
  Integer numProc;
  HpcOmTaskGraph.TaskGraph taskGraph1;
  HpcOmTaskGraph.TaskGraphMeta taskGraphMeta1;
algorithm
  oSchedule := matchcontinue(iTaskGraph,iTaskGraphMeta,iSccSimEqMapping,iFilenamePrefix)
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "level");
        print("Using level Scheduler\n");
      then HpcOmScheduler.createLevelSchedule(iTaskGraphMeta,iSccSimEqMapping);
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "ext");
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
        print("Using external Scheduler\n");
      then HpcOmScheduler.createExtSchedule(iTaskGraph, iTaskGraphMeta, numProc, iSccSimEqMapping, "taskGraph" +& iFilenamePrefix +& "_ext.graphml");
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "listr");
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
      then HpcOmScheduler.createListScheduleReverse(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        true = stringEq(flagValue, "list");
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
      then HpcOmScheduler.createListSchedule(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    case(_,_,_,_)
      equation
        flagValue = Flags.getConfigString(Flags.HPCOM_SCHEDULER);
        print("HpcOmScheduler.createSchedule warning: The scheduler '" +& flagValue +& "' is unknown. The list-scheduling algorithm is used instead.\n");
        numProc = Flags.getConfigInt(Flags.NUM_PROC);
      then HpcOmScheduler.createListSchedule(iTaskGraph,iTaskGraphMeta,numProc,iSccSimEqMapping);
    else
      equation
        print("HpcOmSimCode.createSchedule failed. Maybe the n-Flag was not set correctly\n");
      then fail();
  end matchcontinue;
end createSchedule;

protected function convertToSccSimEqMapping "function convertToSccSimEqMapping
  author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) to the inverse mapping (sccIndex->simEqIndex)."
  input list<tuple<Integer,Integer>> iMapping; //the mapping (simEqIndex -> sccIndex)
  input Integer numOfSccs; //important for arrayCreate
  output array<list<Integer>> oMapping; //the created mapping (sccIndex->simEqIndex)
  
protected
  array<list<Integer>> tmpMapping;

algorithm
  tmpMapping := arrayCreate(numOfSccs,{});
  //print("convertToSccSimEqMapping with " +& intString(numOfSccs) +& " sccs.\n");
  _ := List.fold(iMapping, convertToSccSimEqMapping1, tmpMapping);
  oMapping := tmpMapping;
  
end convertToSccSimEqMapping;

protected function convertToSccSimEqMapping1 "function convertToSccSimEqMapping1
  author: marcusw
  Helper function for convertToSccSimEqMapping. It will update the arrayIndex of the given mapping value."
  input tuple<Integer,Integer> iMapping; //<simEqIdx,sccIdx>
  input array<list<Integer>> iSccMapping;
  output array<list<Integer>> oSccMapping;
  
protected
  Integer i1,i2;
  List<Integer> tmpList;
  
algorithm
  (i1,i2) := iMapping;
  //print("convertToSccSimEqMapping1 accessing index " +& intString(i2) +& ".\n");
  tmpList := arrayGet(iSccMapping,i2);
  tmpList := i1 :: tmpList;
  oSccMapping := arrayUpdate(iSccMapping,i2,tmpList);
  
end convertToSccSimEqMapping1;

protected function convertToSimEqSccMapping "function convertToSimEqSccMapping
  author: marcusw
  Converts the given mapping (simEqIndex -> sccIndex) bases on tuples to an array mapping."
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,sccIdx>
  input Integer numOfSimEqs;
  output array<Integer> oMapping; //maps each simEq to the scc
  
protected
  array<Integer> tmpMapping;
  
algorithm
  tmpMapping := arrayCreate(numOfSimEqs, -1);
  oMapping := List.fold(iMapping, convertToSimEqSccMapping1, tmpMapping);
end convertToSimEqSccMapping;

protected function convertToSimEqSccMapping1 "function convertToSimEqSccMapping1
  author: marcusw
  Helper function for convertToSimEqSccMapping. It will update the array at the given index."
  input tuple<Integer,Integer> iSimEqTuple; //<simEqIdx,sccIdx>
  input array<Integer> iMapping;
  output array<Integer> oMapping;
 
protected
  Integer simEqIdx,sccIdx;
  
algorithm
  (simEqIdx,sccIdx) := iSimEqTuple;
  //print("convertToSimEqSccMapping1 " +& intString(simEqIdx) +& " .. " +& intString(sccIdx) +& " iMapping_len: " +& intString(arrayLength(iMapping)) +& "\n");
  oMapping := arrayUpdate(iMapping,simEqIdx,sccIdx);
end convertToSimEqSccMapping1;

protected function dumpSccSimEqMapping "function dumpSccSimEqMapping
  author: marcusw
  Prints the given mapping out to the console."
  input array<list<Integer>> iSccMapping;
 
protected
  String text;
  
algorithm
  text := "SccToSimEqMapping";
  ((_,text)) := Util.arrayFold(iSccMapping, dumpSccSimEqMapping1, (1,text));
  print(text +& "\n");
end dumpSccSimEqMapping;

protected function dumpSccSimEqMapping1 "function dumpSccSimEqMapping1
  author: marcusw
  Helper function of dumpSccSimEqMapping to print one mapping list."
  input list<Integer> iMapping;
  input tuple<Integer,String> iIndexText;
  output tuple<Integer,String> oIndexText;

protected
  Integer iIndex;
  String text, iText;
  
algorithm
  (iIndex,iText) := iIndexText;
  text := List.fold(iMapping, dumpSccSimEqMapping2, " ");
  text := iText +& "\nSCC " +& intString(iIndex) +& ": {" +& text +& "}";
  oIndexText := (iIndex+1,text);
end dumpSccSimEqMapping1;

protected function dumpSccSimEqMapping2 "function dumpSccSimEqMapping2
  author: marcusw
  Helper function of dumpSccSimEqMapping1 to print one mapping element."
  input Integer iIndex;
  input String iText;
  output String oText;
  
algorithm
  oText := iText +& intString(iIndex) +& " ";
   
end dumpSccSimEqMapping2;

public function getSimCodeEqByIndex "function getSimCodeEqByIndex
  author: marcusw
  Returns the SimEqSystem which has the given Index. This method is called from susan."
  input list<SimCode.SimEqSystem> iEqs; //All SimEqSystems
  input Integer iIdx; //The index of the wanted system
  output SimCode.SimEqSystem oEq;

protected
  list<SimCode.SimEqSystem> rest;
  SimCode.SimEqSystem head;
  Integer headIdx;

algorithm
  oEq := matchcontinue(iEqs,iIdx)
    case(head::rest,_)
      equation
        headIdx = getIndexBySimCodeEq(head);
        //print("getSimCodeEqByIndex listLength: " +& intString(listLength(iEqs)) +& " head idx: " +& intString(headIdx) +& "\n");
        true = intEq(headIdx,iIdx);
      then head;
    case(head::rest,_) then getSimCodeEqByIndex(rest,iIdx);
    else
      equation
        print("getSimCodeEqByIndex failed. Looking for Index " +& intString(iIdx) +& "\n");
      then fail();
  end matchcontinue;
end getSimCodeEqByIndex;

protected function getIndexBySimCodeEq "function getIndexBySimCodeEq
  author: marcusw
  Just a small helper function to get the index of a SimEqSystem."
  input SimCode.SimEqSystem iEq;
  output Integer oIdx;

protected
  Integer index;

algorithm
  oIdx := match(iEq)
    case(SimCode.SES_RESIDUAL(index=index)) then index;
    case(SimCode.SES_SIMPLE_ASSIGN(index=index)) then index;
    case(SimCode.SES_ARRAY_CALL_ASSIGN(index=index)) then index;
    case(SimCode.SES_IFEQUATION(index=index)) then index;
    case(SimCode.SES_ALGORITHM(index=index)) then index;
    case(SimCode.SES_LINEAR(index=index)) then index;
    case(SimCode.SES_NONLINEAR(index=index)) then index;
    case(SimCode.SES_MIXED(index=index)) then index;
    case(SimCode.SES_WHEN(index=index)) then index;
    else then fail();
  end match;
end getIndexBySimCodeEq;

public function analyzeOdeEquations
  input list<list<SimCode.SimEqSystem>> systems;
algorithm
  _ := List.fold(systems, analyzeOdeEquations1, 1);
end analyzeOdeEquations;

protected function analyzeOdeEquations1
  input list<SimCode.SimEqSystem> iEqs;
  input Integer iLevel;
  output Integer oLevel;
algorithm
  print("Equation level " +& intString(iLevel) +& "\n");
  _ := List.fold(iEqs,analyzeOdeEquations2,1);
  oLevel := iLevel + 1;
end analyzeOdeEquations1;

protected function analyzeOdeEquations2
  input SimCode.SimEqSystem iEq;
  input Integer iEqIndex;
  output Integer oEqIndex;
protected
  Integer simEqIdx;
algorithm
  simEqIdx := getIndexBySimCodeEq(iEq);
  print("Equation " +& intString(simEqIdx) +& "\n");
  oEqIndex := iEqIndex + 1;
end analyzeOdeEquations2;

protected function findHighestSccIdxInMapping "function findHighestSccIdxInMapping
  author: marcusw
  Find the highest scc-index in the mapping list."
  input list<tuple<Integer,Integer>> iEquationSccMapping; //<simEqIdx,sccIdx>
  input Integer iHighestIndex;
  output Integer oIndex;

protected
  Integer eqIdx, sccIdx;
  list<tuple<Integer,Integer>> rest;
algorithm
  oIndex := matchcontinue(iEquationSccMapping,iHighestIndex)
    case((eqIdx,sccIdx)::rest,_)
      equation
        true = intGt(sccIdx,iHighestIndex);
      then findHighestSccIdxInMapping(rest,sccIdx);
    case((eqIdx,sccIdx)::rest,_)
      then findHighestSccIdxInMapping(rest,iHighestIndex);
    else
      then iHighestIndex;
  end matchcontinue;
end findHighestSccIdxInMapping;

protected function removeDummyStateFromMapping "function removeDummyStateFromMapping
  author: marcusw
  Removes all mappings with sccIdx=1 from the list and decrements all other scc-indices by 1."
  input list<tuple<Integer,Integer>> iEquationSccMapping;
  output list<tuple<Integer,Integer>> oEquationSccMapping;
algorithm
  oEquationSccMapping := List.fold(iEquationSccMapping, removeDummyStateFromMapping1, {});
end removeDummyStateFromMapping;

protected function removeDummyStateFromMapping1 "function removeDummyStateFromMapping1
  author: marcusw
  Helper function of removeDummyStateFromMapping. Handles one list-element."
  input tuple<Integer,Integer> iTuple; //<eqIdx,sccIdx>
  input list<tuple<Integer,Integer>> iNewList;
  output list<tuple<Integer,Integer>> oNewList;
protected
  Integer eqIdx,sccIdx;
  tuple<Integer,Integer> newElem;
algorithm
  oNewList := matchcontinue(iTuple,iNewList)
    case((eqIdx,sccIdx),_)
      equation
        true = intEq(sccIdx,1);
      then iNewList;
    case((eqIdx,sccIdx),_)
      equation
        newElem = (eqIdx,sccIdx-1);
      then newElem::iNewList;
    else
      equation
        print("removeDummyStateFromMapping1 failed\n");
    then iNewList;
  end matchcontinue;
end removeDummyStateFromMapping1;

// testfunctions
//------------------------------------------
//------------------------------------------

protected function checkOdeSystemSize " compares the size of the ode-taskgraph with the number of ode-equations in the simCode.
author:Waurich TUD 2013-07"
  input HpcOmTaskGraph.TaskGraph taskGraphOdeIn;
  input list<list<SimCode.SimEqSystem>> odeEqsIn;
algorithm
  _ := matchcontinue(taskGraphOdeIn,odeEqsIn)
    local
      Integer actualSize;
      Integer targetSize;
    case(_,_)
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        true = intEq(targetSize,actualSize);
        print("the ODE-system size is correct\n");
        then
          ();
    case(_,_)
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        true = intEq(targetSize,1) and intEq(actualSize,0);
        // there is a dummyDER in the simcode
        print("the ODE-system size is correct\n");
        then
          ();
    else
      equation
        targetSize = listLength(List.flatten(odeEqsIn));
        actualSize = arrayLength(taskGraphOdeIn);
        print("the size should be "+&intString(targetSize)+&" but it is "+&intString(actualSize)+&" !\n");
        print("the ODE-system is NOT correct\n");
      then
        ();
  end matchcontinue;    
end checkOdeSystemSize;

//--------------------------------------------------//
// start new functions for handling linearTornSystems from here
//-------------------------------------------------//

public function traverseEqSystemsWithIndex  "traverse alle EqSystems of the BackendDAE and hold an index of the current torn system.
author:Waurich TUD 2013-10"
  input Integer eqSysIdx;
  input Integer tornSysIdxIn;
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  daeOut := matchcontinue(eqSysIdx,tornSysIdxIn,daeIn)
    local
      Integer tornSysIdx;
      BackendDAE.BackendDAE daeTmp;
      BackendDAE.EqSystem eqSyst;
      BackendDAE.EqSystems eqSysts;
      BackendDAE.Shared shared;
    case(_,_,BackendDAE.DAE(eqs=eqSysts, shared=shared))
      equation
        true = listLength(eqSysts) >= eqSysIdx;
        eqSyst = listGet(eqSysts,eqSysIdx);
        (eqSyst,shared,tornSysIdx) = reduceLinearTornSystem(eqSyst,shared,tornSysIdxIn);
        eqSysts = List.replaceAt(eqSyst,eqSysIdx-1,eqSysts);
        daeTmp = BackendDAE.DAE(eqSysts,shared);
        daeTmp = traverseEqSystemsWithIndex(eqSysIdx+1,tornSysIdx,daeTmp);
      then
        daeTmp;
    case(_,_,BackendDAE.DAE(eqs=eqSysts, shared=shared))
      equation
        true = listLength(eqSysts) < eqSysIdx;
      then
        daeIn;
  end matchcontinue;
end traverseEqSystemsWithIndex;
  
  
public function reduceLinearTornSystem  "checks the EqSystem for tornSystems in order to dissassemble them into various SingleEquation and a reduced EquationSystem.
This is useful in order to reduce the execution costs of the equationsystem and generate a bunch of parallel singleEquations. use +d=doLienarTearing,partlintornsystem to activate it.
Remark: this is still under development
author:Waurich TUD 2013-09"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input Integer tornSysIdxIn;
  output BackendDAE.EqSystem systOut;
  output BackendDAE.Shared sharedOut;
  output Integer tornSysIdxOut;
algorithm
  (systOut, sharedOut, tornSysIdxOut) := matchcontinue(systIn,sharedIn,tornSysIdxIn)
    local
      Integer tornSysIdx;
      array<Integer> ass1, ass2;
      BackendDAE.EqSystem systTmp;
      BackendDAE.EquationArray eqs, eqsTmp;
      BackendDAE.Matching matching;
      BackendDAE.Shared sharedTmp;
      BackendDAE.StrongComponents allComps, compsTmp;
      BackendDAE.Variables vars, varsTmp;
    case(_,_,_)
      equation
        BackendDAE.EQSYSTEM(matching = BackendDAE.MATCHING(ass1=ass1, ass2=ass2, comps= allComps)) = systIn; 
          //BackendDump.dumpEqSystem(systIn,"original system");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(1, allComps, ass1, ass2, systIn,sharedIn,tornSysIdxIn);
          //BackendDump.dumpEqSystem(systTmp,"new system");
        sharedTmp = sharedIn;
      then
        (systTmp, sharedTmp, tornSysIdx);
    else
      equation
        print("reduceLinearTornSystem failed!");
      then 
        fail();
  end matchcontinue;
end reduceLinearTornSystem;


protected function reduceLinearTornSystem1  "traverses all StrongComponents for tornSystems, reduces them and rebuilds the BLT, the matching and the info about vars and equations
author: Waurich TUD 2013-09"
  input Integer compIdx;
  input BackendDAE.StrongComponents compsIn;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Shared sharedIn;
  input Integer tornSysIdxIn;
  output BackendDAE.EqSystem systOut;
  output Integer tornSysIdxOut;
algorithm
  (systOut,tornSysIdxOut) := matchcontinue(compIdx,compsIn,ass1,ass2,systIn,sharedIn,tornSysIdxIn)
    local
      Integer numNewSingleEqs, tornSysIdx;
      Boolean linear;
      array<Integer> ass1New, ass2New, ass1All, ass2All, ass1Other, ass2Other;
      list<Integer> tvarIdcs;
      list<Integer> resEqIdcs;
      list<tuple<Integer,list<Integer>>> otherEqnVarTpl;
      BackendDAE.EqSystem systTmp;
      BackendDAE.EquationArray eqs;
      BackendDAE.Matching matching, matchingNew, matchingOther;
      BackendDAE.Shared sharedTmp;
      BackendDAE.StateSets stateSets;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsNew, compsTmp, otherComps;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqLst, eqsNew, eqsOld, resEqs;
      list<BackendDAE.Var> varLst, varsNew, varsOld, tvars;
    case(_,_,_,_,_,_,_)
      equation
        // completed
        true = listLength(compsIn) < compIdx;
          //print("finished at:"+&intString(compIdx)+&"\n");
      then
        (systIn,tornSysIdxIn);
    case(_,_,_,_,_,_,_)
      equation
        // strongComponent is a linear tornSystem
        true = listLength(compsIn) >= compIdx;
        
        comp = listGet(compsIn,compIdx);
        BackendDAE.TORNSYSTEM(tearingvars = tvarIdcs, residualequations = resEqIdcs, otherEqnVarTpl = otherEqnVarTpl, linear = linear) = comp;
        true = linear;
           //print("handle tornsystem with compnumber:"+&intString(compIdx)+&"\n");
           //BackendDump.dumpEqSystem(systIn,"the original system");
        // build the new components, the new variables and the new equations
          
        (varsNew,eqsNew,tvars,resEqs,matchingNew) = reduceLinearTornSystem2(systIn,sharedIn,tvarIdcs,resEqIdcs,otherEqnVarTpl,tornSysIdxIn);
        
        BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) = matchingNew;
                  
        // add the new vars and equations to the original EqSystem
        BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs, stateSets = stateSets) = systIn;
        varsOld = BackendVariable.varList(vars);
        eqsOld = BackendEquation.equationList(eqs);
                       
        varLst = listAppend(varsOld,varsNew);
        eqLst = listAppend(eqsOld, eqsNew);
        eqLst = List.fold2(List.intRange(listLength(resEqIdcs)),replaceAtPositionFromList,resEqs,resEqIdcs,eqLst);  // replaces the old residualEquations with the new ones
        vars = BackendVariable.listVar1(varLst);  // !!! BackendVariable.listVar outputs the reversed order therefore listVar1
        eqs = BackendEquation.listEquation(eqLst);      
        
        //print("new systemsize:"+&intString(listLength(varLst))+&" vars. and "+&intString(listLength(eqLst))+&" eqs\n");
                
        // build the matching
        ass1All = arrayCreate(listLength(varLst),-1);
        ass2All = arrayCreate(listLength(varLst),-1);  // actually has to be listLength(eqLst), but there is stille the probelm taht ass1 and ass2 have the same size
        ass1All = Util.arrayCopy(ass1,ass1All);  // the comps before and after the tornsystem
        ass2All = Util.arrayCopy(ass2,ass2All);
        ((ass1All, ass2All)) = List.fold2(List.intRange(listLength(tvarIdcs)),updateResidualMatching,tvarIdcs,resEqIdcs,(ass1All,ass2All));  // sets matching info for the tearingVars and residuals
        
        // get the otherComps and and update the matching for the othercomps
        matchingOther = getOtherComps(otherEqnVarTpl,ass1All,ass2All);      
        BackendDAE.MATCHING(ass1=ass1Other, ass2=ass2Other, comps=otherComps) = matchingOther;
        
        // insert the new components into the BLT instead of the TornSystem, append the updated blocks for the other equations, update matching for the new equations
        numNewSingleEqs = listLength(compsNew)-listLength(tvarIdcs);
          //print("num of new comps:"+&intString(numNewSingleEqs)+&"\n");
          //BackendDump.dumpComponents(compsNew);
        compsNew = listAppend(compsNew, otherComps);
        compsTmp = List.replaceAtWithList(compsNew,compIdx-1,compsIn);
        ((ass1All,ass2All)) = List.fold2(List.intRange(arrayLength(ass1New)),updateMatching,(listLength(eqsOld),listLength(varsOld)),(ass1New,ass2New),(ass1All,ass2All));               
        matching = BackendDAE.MATCHING(ass1All, ass2All, compsTmp);
        
        //build new EqSystem
        systTmp = BackendDAE.EQSYSTEM(vars,eqs,NONE(),NONE(),matching,stateSets);
        (systTmp,_,_) = BackendDAEUtil.getIncidenceMatrix(systTmp, BackendDAE.NORMAL(),NONE());
          //BackendDump.dumpEqSystem(systTmp,"the whole new system");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(compIdx+1+numNewSingleEqs,compsTmp,ass1All,ass2All,systTmp,sharedIn,tornSysIdxIn+1);
      then
        (systTmp,tornSysIdx);
    else
      // go to next StrongComponent
      equation
        //print("no torn system in comp:"+&intString(compIdx)+&"\n");
        (systTmp,tornSysIdx) = reduceLinearTornSystem1(compIdx+1,compsIn,ass1,ass2,systIn,sharedIn,tornSysIdxIn);
      then
        (systTmp,tornSysIdx);
  end matchcontinue;
end reduceLinearTornSystem1;

  
protected function reduceLinearTornSystem2  " builds from a torn system various linear equation systems that can be computed in parallel.
author: Waurich TUD 2013-07"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input list<Integer> tearingVars;
  input list<Integer> residualEqs;
  input list<tuple<Integer, list<Integer>>> otherEqsVarTpl;
  input Integer tornSysIdx;
  output list<BackendDAE.Var> varsNewOut;
  output list<BackendDAE.Equation> eqsNewOut;
  output list<BackendDAE.Var> tVarsOut;
  output list<BackendDAE.Equation> resEqsOut;
  output BackendDAE.Matching matchingOut;
protected
  array<Integer> ass1New, ass2New;
  Integer size, otherEqSize, compSize;
  list<Integer> otherEqnsInts, otherVarsInts, tVarRange, rEqIdx;
  list<list<Integer>> otherVarsIntsLst;
  BackendDAE.EqSystem systNew;
  BackendDAE.EquationArray eqns,  oeqns, hs0Eqs;
  BackendDAE.Matching matchingNew;
  BackendDAE.StrongComponent rComp;
  BackendDAE.StrongComponents comps, compsNew, oComps;
  BackendDAE.Variables vars, kv,  diffVars, ovars, dVars;
  BackendVarTransform.VariableReplacements repl, repl1;
  DAE.FunctionTree functree;
  list<BackendDAE.Equation> eqLst,reqns, otherEqnsLst,otherEqnsLstReplaced, eqNew, hs, hs1;
  list<BackendDAE.EquationArray> gEqs, hEqs, hsEqs;
  list<BackendDAE.Var> varLst, tvars, tvarsReplaced, ovarsLst, xa0, a_0, varNew;
  list<BackendDAE.Variables> xaVars, rVars, aVars;
  list<BackendVarTransform.VariableReplacements> replLst;
  list<list<BackendDAE.Equation>> g_i_lst, g_i_lst1, h_i_lst, h_i_lst1, hs_i_lst, hs_i_lst1, hs_0_lst;
  list<list<BackendDAE.Var>> xa_i_lst, xa_i_lst1, r_i_lst, r_i_lst1, a_i_lst, a_i_lst1;
  list<DAE.ComponentRef> tcrs,ovcrs;
algorithm
   // handle torn systems for the linear case
   BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs = eqns, matching = BackendDAE.MATCHING(comps=comps)) := isyst;
   BackendDAE.SHARED(knownVars=kv, functionTree=functree) := ishared;
   eqLst := BackendEquation.equationList(eqns);
   varLst := BackendVariable.varList(vars);
   tvars := List.map1r(tearingVars, BackendVariable.getVarAt, vars);
   tvarsReplaced := List.map(tvars, SimCodeUtil.transformXToXd);
   tcrs := List.map(tvarsReplaced, BackendVariable.varCref);
      
   // get residual eqns
   reqns := BackendEquation.getEqns(residualEqs, eqns);
   reqns := SimCodeUtil.replaceDerOpInEquationList(reqns);
   
   // get the other equations and the other variables
   otherEqnsInts := List.map(otherEqsVarTpl, Util.tuple21);
   otherEqnsLst := BackendEquation.getEqns(otherEqnsInts, eqns);
   oeqns := BackendEquation.listEquation(otherEqnsLst);
   otherEqnsLstReplaced := SimCodeUtil.replaceDerOpInEquationList(otherEqnsLst);   // for computing the new equations
   
   otherVarsIntsLst := List.map(otherEqsVarTpl, Util.tuple22);
   otherVarsInts := List.unionList(otherVarsIntsLst);
   ovarsLst := List.map1r(otherVarsInts, BackendVariable.getVarAt, vars);
   ovarsLst := List.map(ovarsLst, SimCodeUtil.transformXToXd);  //try this
   ovars := BackendVariable.listVar1(ovarsLst);
   ovcrs := List.map(ovarsLst, BackendVariable.varCref);
      
   //build the components and systems to get the system for computing the tearingVars
   size := listLength(tvars);
   otherEqSize := listLength(otherEqnsLst);
   compSize := listLength(comps);
   tVarRange := List.intRange2(0,size);
   repl1 := BackendVarTransform.emptyReplacements();
   
   //  get g_i(xt=e_i, xa=xa_i) with xa_i as variables to be solved
   (g_i_lst,xa_i_lst,replLst) := getAlgebraicEquationsForEI(tVarRange,size,otherEqnsLstReplaced,tvarsReplaced,tcrs,ovarsLst,ovcrs,{},{},{},tornSysIdx);
   (g_i_lst1,xa_i_lst1,repl1) := simplifyEquations(g_i_lst,xa_i_lst,repl1);
     
     //dumpVarLstLst(xa_i_lst,"xa");
     //dumpEqLstLst(g_i_lst,"g");
   
   //  compute residualValues h_i(xt=e_i,xa_i,r_i) for r_i
   (h_i_lst,r_i_lst) := addResidualVarToEquation(tVarRange,reqns,{},{},tornSysIdx);
   h_i_lst := replaceVarsInResidualEquations(tVarRange,h_i_lst,replLst,{});
   (h_i_lst1,r_i_lst1,repl1) := simplifyEquations(h_i_lst,r_i_lst,repl1);
   
      //dumpVarLstLst(r_i_lst,"r");
      //dumpEqLstLst(h_i_lst,"h");
   
   //  get the co-efficients for the new residualEquations a_i from hs_i(r_i,xt=e_i, a_i) 
   (hs_i_lst,a_i_lst) := getTornSystemCoefficients(tVarRange,size,r_i_lst,{},{},tornSysIdx);
   (hs_i_lst1,a_i_lst1,repl1) := simplifyEquations(hs_i_lst,a_i_lst,repl1);
   
      //dumpVarLstLst(a_i_lst,"a");
      //dumpEqLstLst(hs_i_lst,"hs_i");
   
   // gather all additional equations and build the strongComponents (not including the new residual equation)
   eqsNewOut := List.flatten(listAppend(listAppend(g_i_lst1,h_i_lst1),hs_i_lst1));
   varsNewOut := List.flatten(listAppend(listAppend(xa_i_lst1,r_i_lst1),a_i_lst1));
   matchingNew := buildSingleEquationSystem(compSize,eqsNewOut,varsNewOut,ishared,{});
   BackendDAE.MATCHING(ass1=ass1New, ass2=ass2New, comps=compsNew) := matchingNew;
   
   //BackendDump.dumpComponents(compsNew);
   
   compsNew := List.map2(compsNew,updateIndicesInComp,listLength(varLst),listLength(eqLst));
   
   //BackendDump.dumpVarList(varsNewOut,"varsNew");
   //BackendDump.dumpEquationList(eqsNewOut,"eqsNew");

   // compute the tearing vars in the new residual equations hs
   (a_0::a_i_lst) := a_i_lst;
   //a_0 := listReverse(a_0);
   
   hs := buildNewResidualEquation(1,a_i_lst,a_0,tvars,{});
   (hs1,_) := BackendVarTransform.replaceEquations(hs,repl1,NONE());
   tVarsOut := tvars;
   resEqsOut := hs1;
   
   //// get the strongComponent for the residual equations and add it at the end of the new StrongComponents
   rComp := BackendDAE.EQUATIONSYSTEM(residualEqs,tearingVars,NONE(),BackendDAE.JAC_NO_ANALYTIC());   
   
   oComps := List.appendElt(rComp,compsNew);
   matchingOut := BackendDAE.MATCHING(ass1New,ass2New,oComps);
   
   //printPartLinTornInfo(tcrs,reqns,otherEqnsLst,ovcrs,xa_i_lst,g_i_lst,r_i_lst,h_i_lst,a_i_lst,hs_i_lst,hs,compsNew);
end reduceLinearTornSystem2; 


protected function updateMatching "inserts the information of matching2 into matching1 by adding an index offset for the vars and eqs of matching2.Actually only one assignment for matching 2 is needed.
author: Waurich TUD 2013-09"
  input Integer idx;
  input tuple<Integer,Integer> offsetTpl;
  input tuple<array<Integer>,array<Integer>> matching2;
  input tuple<array<Integer>,array<Integer>> matching1In;
  output tuple<array<Integer>,array<Integer>> matching1Out;
protected
  Integer eqOffset, varOffset, eqValue, varValue;
  array<Integer> ass11, ass21, ass12, ass22;
algorithm
  (eqOffset, varOffset) := offsetTpl;
  (ass12, ass22) := matching2;
  (ass11, ass21) := matching1In;
  eqValue := idx + eqOffset;
  varValue := arrayGet(ass22,idx)+varOffset;
  ass11 := arrayUpdate(ass11,varValue,eqValue);
  ass21 := arrayUpdate(ass21, eqValue, varValue);
  matching1Out := (ass11, ass21);
end updateMatching;


protected function updateResidualMatching "sets the matching between tearingVars and residuals.
author: Waurich TUD 2013-09"
  input Integer idx;
  input list<Integer> tvars;
  input list<Integer> resEqs;
  input tuple<array<Integer>,array<Integer>> tplIn;
  output tuple<array<Integer>,array<Integer>> tplOut;
protected
  array<Integer> ass1, ass2;
  Integer eqIdx, varIdx;
algorithm
  (ass1,ass2) := tplIn;
  eqIdx := listGet(resEqs,idx);
  varIdx := listGet(tvars,idx);
  ass1 := arrayUpdate(ass1,varIdx,eqIdx);
  ass2 := arrayUpdate(ass2,eqIdx,varIdx);
  tplOut := (ass1,ass2);
end updateResidualMatching;


protected function getOtherComps "builds ordered StrongComponents and matching for the other equations.
author: Waurich TUD 2013-09" 
  input list<tuple<Integer, list<Integer>>> otherEqsVarTpl;
  input array<Integer> ass1;
  input array<Integer> ass2;
  output BackendDAE.Matching matchingOut;
protected
  array<Integer> ass1Tmp, ass2Tmp;
  BackendDAE.StrongComponents compsTmp;
algorithm
  ((ass1Tmp,ass2Tmp,compsTmp)) := List.fold(otherEqsVarTpl,getOtherComps1,(ass1,ass2,{}));
  compsTmp := listReverse(compsTmp);
  matchingOut := BackendDAE.MATCHING(ass1Tmp,ass2Tmp,compsTmp);
end getOtherComps;


protected function getOtherComps1 "implementation of getOtherComps
author:waurich TUD 2013-09"
  input tuple<Integer,list<Integer>> otherEqsVarTpl;
  input tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplIn;
  output tuple<array<Integer>, array<Integer>, BackendDAE.StrongComponents> tplOut;
algorithm
  tplOut := matchcontinue(otherEqsVarTpl, tplIn)
    local
      Integer eqIdx, varIdx;
      array<Integer> ass1, ass2;
      list<Integer> varIdcs;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents compsIn, compsTmp;
    case((eqIdx, varIdcs),(ass1,ass2,compsIn))
      equation
        true = listLength(varIdcs) == 1;
        varIdx = listGet(varIdcs,1);
        comp = BackendDAE.SINGLEEQUATION(eqIdx,varIdx);
        ass1 = arrayUpdate(ass1,varIdx,eqIdx);
        ass2 = arrayUpdate(ass2,eqIdx,varIdx);    
        compsTmp = comp::compsIn;
      then
        ((ass1,ass2,compsTmp));
    else
      equation
        print("getOtherComps failed\n");
      then
        fail();
  end matchcontinue;
end getOtherComps1;


protected function replaceAtPositionFromList  "replaces the entry from inLst indexed by positionLst[n] with with the nth entry in replacingLst. n is first input so it can be used in a folding functions.
author: Waurich TUD 2013-09"
  replaceable type ElementType subtypeof Any;
  input Integer n;
  input list<ElementType> replacingLst;
  input list<Integer> positionLst;
  input list<ElementType> inLst;
  output list<ElementType> outLst;
protected
  Integer idx;
  ElementType entry;
algorithm
  idx := listGet(positionLst,n);
  entry := listGet(replacingLst,n);
  outLst := List.replaceAt(entry,idx-1,inLst);
end replaceAtPositionFromList; 


protected function updateIndicesInComp " raises the indices of the vars and eqs in the given component according to the given offsets.
author: Waurich TUD 2013-09"
  input BackendDAE.StrongComponent compIn;
  input Integer varOffset;
  input Integer eqOffset;
  output BackendDAE.StrongComponent compOut;
algorithm
  compOut := matchcontinue(compIn,varOffset,eqOffset)
    local
      Integer varIdx;
      Integer eqIdx;
      BackendDAE.StrongComponent compTmp;
    case(BackendDAE.SINGLEEQUATION(eqn=eqIdx, var=varIdx),_,_)
      equation
        varIdx = varIdx+varOffset;
        eqIdx = eqIdx+eqOffset;
        compTmp = BackendDAE.SINGLEEQUATION(eqIdx, varIdx);
      then
        compTmp;
    else
      equation
        print("updateVarEqIndices failed\n");
      then
        fail();
  end matchcontinue;
end updateIndicesInComp;

protected function buildNewResidualEquation "function to build the new linear residual equations res=0=A*xt+a0 whicht is solved for xt
author: Waurich TUD 2013-09"
  input Integer resIdx;
  input list<list<BackendDAE.Var>> aCoeffLst;
  input list<BackendDAE.Var> a0CoeffLst;
  input list<BackendDAE.Var> tvars;
  input list<BackendDAE.Equation> resEqsIn;
  output list<BackendDAE.Equation> resEqsOut;
algorithm
  resEqsOut := matchcontinue(resIdx,aCoeffLst,a0CoeffLst,tvars,resEqsIn)
    local
      list<BackendDAE.Equation> eqLstTmp;
      list<BackendDAE.Var> aCoeffs;
      BackendDAE.Equation eqTmp, hs;
      BackendDAE.Var a0Coeff;
      DAE.Exp lhs, rhs, a0Exp;
      DAE.Type ty;
    case(_,_,_,_,_)
      equation
        true = resIdx > listLength(tvars);
        eqLstTmp = listReverse(resEqsIn);
      then
        eqLstTmp;
    case(_,_,_,_,_)
      equation
        true = resIdx <= listLength(tvars);
        //aCoeffs = listGet(aCoeffLst,resIdx);
        //aCoeffs = listReverse(aCoeffs);
        aCoeffs = List.map1(aCoeffLst,listGet,resIdx);
        a0Coeff = listGet(a0CoeffLst,resIdx);
        a0Exp = varExp(a0Coeff);
        ty = DAE.T_REAL_DEFAULT;
        rhs = buildNewResidualEquation2(1,aCoeffs,tvars,DAE.RCONST(0.0)); // the start value is random and will be rejected
        rhs = DAE.BINARY(rhs, DAE.ADD(ty), a0Exp);
        lhs = DAE.RCONST(0.0);
        hs = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,false);
        eqLstTmp = hs::resEqsIn;
        eqLstTmp = buildNewResidualEquation(resIdx+1,aCoeffLst,a0CoeffLst,tvars,eqLstTmp);
      then
        eqLstTmp;      
    else
      equation
        print("buildNewResidualEquation failed");
      then
        fail();
  end matchcontinue;
end buildNewResidualEquation;


protected function buildNewResidualEquation2 "function to build the sum of the rhs of the new residual equation, i.e. the sum of all tvars and their coefficients
author: Waurich TUD 2013-09"
  input Integer idx;
  input list<BackendDAE.Var> coeffs;
  input list<BackendDAE.Var> tVars;
  input DAE.Exp expIn;
  output DAE.Exp expOut;
algorithm
  expOut := matchcontinue(idx,coeffs,tVars,expIn)
    local
      BackendDAE.Var coeff;
      BackendDAE.Var tVar;
      DAE.Exp coeffExp, tVarExp, expTmp;
      DAE.Type ty;
    case(_,_,_,_)
      equation
        // the first product of the term
        true = idx == 1;
        coeff = listGet(coeffs,idx);
        coeffExp = varExp(coeff);
        tVar = listGet(tVars,idx);
        tVarExp = varExp(tVar);
        tVarExp = Debug.bcallret1(BackendVariable.isStateVar(tVar), Expression.expDer, tVarExp, tVarExp); // if tvar is a state, use the der(varexp)
        ty = DAE.T_REAL_DEFAULT;
        expTmp = DAE.BINARY(coeffExp,DAE.MUL(ty),tVarExp);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then
        expTmp;
    case(_,_,_,_)
      equation
        true = idx <= listLength(tVars);
        //extend the expression
        coeff = listGet(coeffs,idx);
        tVar = listGet(tVars,idx);
        expTmp = addProductToExp(coeff,tVar,expIn);
        expTmp = buildNewResidualEquation2(idx+1,coeffs,tVars,expTmp);
      then
        expTmp;
    case(_,_,_,_)
      equation
        true = idx > listLength(tVars);
      then
        expIn;
    else
      equation
        print("buildNewResidualEquation2 failed!\n");
      then
        fail();
  end matchcontinue;
end buildNewResidualEquation2;


protected function addProductToExp " function to add the product of the given 2 BackendDAE.Var to the given inExp. expOut = expIn + fac1*fac2
author: Waurich TUD 2013-09"
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  input DAE.Exp inExp;
  output DAE.Exp expOut;
protected
  DAE.Exp fac1, fac2, prod;
  DAE.Type ty;
algorithm
  fac1 := varExp(var1);
  fac2 := varExp(var2);
  fac2 := Debug.bcallret1(BackendVariable.isStateVar(var2), Expression.expDer, fac2, fac2);
  ty := DAE.T_REAL_DEFAULT;
  prod := DAE.BINARY(fac1, DAE.MUL(ty), fac2);
  expOut := DAE.BINARY(inExp, DAE.ADD(ty), prod);
end addProductToExp;


protected function buildSingleEquationSystem "function to build a system of singleEquations which can be solved partially parallel, from an EquationArray and Variables.
author: Waurich TUD 2013-07" 
  input Integer eqSizeOrig;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents compsIn;
  output BackendDAE.Matching matchingOut;
algorithm
  matchingOut := matchcontinue(eqSizeOrig,inEqs,inVars,shared,compsIn)
    local
      array<list<Integer>> mapEqnIncRow;
      array<Integer> ass1, ass2;
      array<Integer> mapIncRowEqn;
      Integer nVars, nEqs, compIdxTmp;
      BackendDAE.EquationArray eqArr;
      BackendDAE.EqSystem sysTmp;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Matching matching, matchingTmp;
      BackendDAE.StrongComponents compsTmp;
      BackendDAE.Variables vars;
    case(_,_,_,_,_)
      equation        
        // build a singleEquation from a list<Equation> and list<Var> which are indexed by compIdx;
        // get the EQSYSTEM, the incidenceMatrix and a matching
        vars = BackendVariable.listVar1(inVars);
        eqArr = BackendEquation.listEquation(inEqs);
        sysTmp = BackendDAE.EQSYSTEM(vars,eqArr,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        (sysTmp,m,mt) = BackendDAEUtil.getIncidenceMatrix(sysTmp,BackendDAE.NORMAL(),NONE());
        nVars = listLength(inVars);
        nEqs = listLength(inEqs);
        ass1 = arrayCreate(nVars, -1);
        ass2 = arrayCreate(nEqs, -1);
        Matching.matchingExternalsetIncidenceMatrix(nVars, nEqs, m);
        BackendDAEEXT.matching(nVars, nEqs, 5, -1, 0.0, 1);
        BackendDAEEXT.getAssignment(ass2, ass1);
        matching = BackendDAE.MATCHING(ass1, ass2, {});
        sysTmp = BackendDAE.EQSYSTEM(vars,eqArr,SOME(m),SOME(mt),matching,{});

        // perform BLT to order the StrongComponents
        mapIncRowEqn = listArray(List.intRange(nEqs));
        mapEqnIncRow = Util.arrayMap(mapIncRowEqn,List.create);
        (sysTmp,compsTmp) = BackendDAETransform.strongComponentsScalar(sysTmp,shared,mapEqnIncRow,mapIncRowEqn);
        sysTmp = BackendDAE.EQSYSTEM(vars,eqArr,SOME(m),SOME(mt),matching,{});
        compsTmp = listAppend(compsIn,compsTmp);
        matchingTmp = BackendDAE.MATCHING(ass1, ass2, compsTmp);
      then
        matchingTmp;
    else
      equation
        print("buildSingleEquationSystem failed\n");
      then
        fail();
  end matchcontinue;
end buildSingleEquationSystem;


protected function getTornSystemCoefficients "gets the co-efficients for the new residual equations of the linear torn system
the first index is for the residualvar and the second for the tearingvar
(r1) = (a11 a12..) (xt1)+(a01)
(r2) = (a21 a22..)*(xt2)+(a02)    
(:)  = (:   :    ) ( : )+( : )
this is meant to be a matrix :)
author: Waurich TUD 2013-08"
  input list<Integer> iValueRange;
  input Integer numTVars;
  input list<list<BackendDAE.Var>> r_i_lstIn;
  input list<list<BackendDAE.Equation>> hs_i_lstIn;
  input list<list<BackendDAE.Var>> a_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> hs_i_lstOut;
  output list<list<BackendDAE.Var>> a_i_lstOut;
algorithm
  (hs_i_lstOut,a_i_lstOut) := matchcontinue(iValueRange, numTVars, r_i_lstIn, hs_i_lstIn, a_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String varName;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> hs_i;
      list<BackendDAE.Var> a_i, r_i;
      list<list<BackendDAE.Equation>> hs_i_lstTmp;
      list<list<BackendDAE.Var>> a_i_lstTmp;
      BackendDAE.Var aVar;
      DAE.ComponentRef varCRef;
      DAE.Exp varExp;
    case({},_,_,_,_,_)
      equation
        //completed
        hs_i_lstTmp = listDelete(hs_i_lstIn,0);
        a_i_lstTmp = listDelete(a_i_lstIn,0);
        hs_i_lstTmp = listReverse(hs_i_lstTmp);
        a_i_lstTmp = listReverse(a_i_lstTmp);
      then
        (hs_i_lstTmp,a_i_lstTmp);
    case(iValue::iLstRest,_,_,_,_,_)
      equation
        // gets the equations for computing the coefficients for the new residual equations
        r_i = listGet(r_i_lstIn,iValue+1);
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients1(List.intRange(numTVars),iValue,r_i,hs_i_lstIn,a_i_lstIn,tornSysIdx);
        //BackendDump.dumpVarList(listGet(a_i_lstTmp,1),"a_"+&intString(iValue)+&"\n");
        //BackendDump.dumpEquationList(listGet(hs_i_lstTmp,1),"hs_"+&intString(iValue)+&"\n");
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients(iLstRest,numTVars,r_i_lstIn,{}::hs_i_lstTmp,{}::a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp,a_i_lstTmp);
    else
      equation
        print("getTornSystemCoefficients failed!\n");
      then
        fail();
  end matchcontinue;
end getTornSystemCoefficients;


protected function getTornSystemCoefficients1 "gets the equations with coefficients for one e_i
author: Waurich TUD 2013-08"
  input list<Integer> resIdxLst; 
  input Integer iIdx;
  input list<BackendDAE.Var> resVal_iIn;
  input list<list<BackendDAE.Equation>>hs_i_lstIn;
  input list<list<BackendDAE.Var>> a_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> hs_i_lstOut;
  output list<list<BackendDAE.Var>> a_i_lstOut;
algorithm
  (hs_i_lstOut, a_i_lstOut) := matchcontinue(resIdxLst, iIdx, resVal_iIn, hs_i_lstIn, a_i_lstIn,tornSysIdx)
    local
      Integer resIdx,resIdx1;
      String aName;
      list<Integer> resIdxRest;
      list<list<BackendDAE.Equation>> hs_i_lstTmp;
      list<list<BackendDAE.Var>> a_i_lstTmp;
      list<BackendDAE.Equation> hs_iTmp;
      list<BackendDAE.Var> a_iTmp, d_lst;
      BackendDAE.Equation hs_ii;
      BackendDAE.Var a_ii, r_ii, dVar;
      DAE.ComponentRef aCRef;
      DAE.Exp aExp, lhs, rhs, dExp;
      DAE.Type ty;
    case({},_,_,_,_,_)
      equation
        //complete
        //hs_i_lstTmp = listReverse(hs_i_lstIn);
        //a_i_lstTmp = listReverse(a_i_lstIn);
      then
        (hs_i_lstIn,a_i_lstIn);
    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = intEq(0,iIdx);
        // build the coefficients (offset d=a_0) of the new residual equations (hs = A*xt+d)
        aName = "$a_"+&intString(tornSysIdx)+&intString(iIdx)+&"_"+&intString(resIdx);
        //aName = "$a_"+&intString(resIdx)+&"_"+&intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        aExp = Expression.makeCrefExp(aCRef,ty);
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
        // build the equations to solve for the coefficients
        resIdx1 = listLength(resVal_iIn)+1-resIdx;
        r_ii = listGet(resVal_iIn,resIdx1);
        lhs = varExp(r_ii);
        rhs = varExp(a_ii);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,false);
        // update th a_i_lst and the hs_i_lst
        a_i_lstTmp = Debug.bcallret1(List.isEmpty(a_i_lstIn), List.create, {a_ii},varInFrontList(a_ii,a_i_lstIn));
        hs_i_lstTmp = Debug.bcallret1(List.isEmpty(hs_i_lstIn), List.create, {hs_ii}, eqInFrontList(hs_ii,hs_i_lstIn));
        //next residual equation
        (hs_i_lstTmp,a_i_lstTmp) = getTornSystemCoefficients1(resIdxRest,iIdx,resVal_iIn,hs_i_lstTmp,a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp, a_i_lstTmp);
    case(resIdx::resIdxRest,_,_,_,_,_)
      equation
        true = iIdx > 0;
        // build the co-efficients (A-matrix-entries) of the new residual equations (hs = A*xt+d)
        //aName = "$a_"+&intString(iIdx)+&"_"+&intString(resIdx);
        aName = "$a_"+&intString(tornSysIdx)+&intString(resIdx)+&"_"+&intString(iIdx);
        ty = DAE.T_REAL_DEFAULT;
        aCRef = ComponentReference.makeCrefIdent(aName,ty,{});
        aExp = Expression.makeCrefExp(aCRef,ty);
        a_ii = BackendDAE.VAR(aCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
        // build the equations to solve for the coefficients
        resIdx1 = listLength(resVal_iIn)+1-resIdx;
        d_lst = List.last(a_i_lstIn);
        dVar = listGet(d_lst, resIdx1);
        dExp = varExp(dVar);
        aExp = varExp(a_ii);
        rhs = DAE.BINARY(aExp,DAE.ADD(ty),dExp);
        r_ii = listGet(resVal_iIn,resIdx1);
        lhs = varExp(r_ii);
        hs_ii = BackendDAE.EQUATION(lhs,rhs,DAE.emptyElementSource,false);
        // update th a_i_lst and the hs_i_lst
        a_i_lstTmp = Debug.bcallret1(List.isEmpty(a_i_lstIn), List.create, {a_ii},varInFrontList(a_ii, a_i_lstIn));
        hs_i_lstTmp = Debug.bcallret1(List.isEmpty(hs_i_lstIn), List.create, {hs_ii}, eqInFrontList(hs_ii, hs_i_lstIn));
        // next residual equation
        (hs_i_lstTmp, a_i_lstTmp) = getTornSystemCoefficients1(resIdxRest, iIdx, resVal_iIn, hs_i_lstTmp, a_i_lstTmp,tornSysIdx);
      then
        (hs_i_lstTmp, a_i_lstTmp);
    else
      equation
        print("getTornSystemCoefficients1 failed\n");
      then
        fail();
  end matchcontinue;
end getTornSystemCoefficients1;
        

protected function varExp "gets an DAE.Exp for the CREF of the given BackendDAE.Var
author: Waurich TUD 2013-08"
  input BackendDAE.Var varIn;
  output DAE.Exp expOut;
protected
  DAE.ComponentRef cr;
  DAE.Type ty;
algorithm
  ty := BackendVariable.varType(varIn);
  cr := BackendVariable.varCref(varIn);
  expOut := DAE.CREF(cr,ty);
end varExp;


protected function replaceVarsInResidualEquations "replaces the otherVars with xa_i and the tvars with e_i
author: Waurich TUD 2013-08"
  input list<Integer> iValueRange;
  input list<list<BackendDAE.Equation>> resEqsIn;
  input list<BackendVarTransform.VariableReplacements> inReplLst;
  input list<list<BackendDAE.Equation>> h_i_lstIn;
  output list<list<BackendDAE.Equation>> h_i_lstOut;
algorithm
  h_i_lstOut := matchcontinue(iValueRange,resEqsIn,inReplLst,h_i_lstIn)
    local
      Integer iValue;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> h_i_Eqs;
      BackendVarTransform.VariableReplacements repl;
      list<list<BackendDAE.Equation>> h_i_lstTmp;
    case({},_,_,_)
      //completed
      equation
        h_i_lstTmp = listReverse(h_i_lstIn);
      then
        h_i_lstTmp;
    case(iValue::iLstRest,_,_,_)
      equation
        iValue = iValue+1;
        repl = listGet(inReplLst,iValue);
        h_i_Eqs = listGet(resEqsIn,iValue);
        (h_i_Eqs,_) = BackendVarTransform.replaceEquations(h_i_Eqs,repl,NONE());
        h_i_lstTmp = replaceVarsInResidualEquations(iLstRest,resEqsIn,inReplLst,h_i_Eqs::h_i_lstIn);        
      then
       h_i_lstTmp;
    else
      equation
        print("replaceVarsInResidualEquations failed \n");  
      then
        fail();      
  end matchcontinue;
end replaceVarsInResidualEquations;


protected function addResidualVarToEquation "adds a variable r_x to  the right hand side of an equation. this corresponds to the residual value in a residual equation
author: Waurich TUD 2013-08"
  input list<Integer> iIn; 
  input list<BackendDAE.Equation> resEqLstIn;
  input list<list<BackendDAE.Equation>> h_i_lstIn;
  input list<list<BackendDAE.Var>> r_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> h_i_lstOut;
  output list<list<BackendDAE.Var>> r_i_lstOut;
algorithm
  (h_i_lstOut,r_i_lstOut) := matchcontinue(iIn,resEqLstIn,h_i_lstIn,r_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String resVarName;
      list<Integer> eqIdxRange;
      list<Integer> iLstRest;
      list<list<BackendDAE.Equation>> h_i_lstTmp;
      list<list<BackendDAE.Var>> r_i_lstTmp;
      BackendDAE.Equation resEq;
      DAE.Exp exp1;
      DAE.Exp exp2;
      DAE.Exp scalarExp;
    case({},_,_,_,_)
      // completed
      equation
        h_i_lstTmp = listDelete(h_i_lstIn,0);
        r_i_lstTmp = listDelete(r_i_lstIn,0);
        h_i_lstTmp = listReverse(h_i_lstTmp);
        r_i_lstTmp = listReverse(r_i_lstTmp);
      then
        (h_i_lstTmp,r_i_lstTmp);
    case(iValue::iLstRest,_,_,_,_)
      // traverse the residualEquations
      equation
        eqIdxRange = List.intRange(listLength(resEqLstIn));
        resVarName = "r_"+&intString(tornSysIdx)+&intString(iValue);
        ((h_i_lstTmp,r_i_lstTmp)) = List.fold2(eqIdxRange,addResidualVarToEquation1,resEqLstIn,resVarName,(h_i_lstIn, r_i_lstIn));
        //BackendDump.dumpVarList(listGet(r_i_lstTmp,1),"r_"+&intString(iValue)+&"\n");
        //BackendDump.dumpEquationList(listGet(h_i_lstTmp,1),"h_"+&intString(iValue)+&"\n");
        (h_i_lstTmp,r_i_lstTmp) = addResidualVarToEquation(iLstRest,resEqLstIn,{}::h_i_lstTmp,{}::r_i_lstTmp,tornSysIdx);
      then
        (h_i_lstTmp,r_i_lstTmp);        
    else
      equation
        print("addResidualVarToEquation failed! \n");
      then
        fail(); 
  end matchcontinue;
end addResidualVarToEquation;


protected function addResidualVarToEquation1 "function to parse the expressions of one residualEquation. creates the residuumVars and updates the residual Expressions with them
author:Waurich TUD 2013-08 "
  input Integer eqIdx;
  input list<BackendDAE.Equation> resEqLstIn;
  input String resVarName;
  input tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>> tplIn;
  output tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>> tplOut;
protected 
  String resName;
  list<BackendDAE.Equation> resEqLst;
  list<BackendDAE.Var> resVarLst;
  list<list<BackendDAE.Equation>> h_i_lst;
  list<list<BackendDAE.Var>> r_i_lst;
  BackendDAE.Equation resEq;
  BackendDAE.Var resVal;
  DAE.ComponentRef resCRef;
  DAE.Exp resExp;
  DAE.Type ty;
algorithm
  (h_i_lst,r_i_lst):= tplIn;
  // add the variable for the residuumValue
  resEq := listGet(resEqLstIn,eqIdx);
  resName := "$"+&resVarName +&"_"+& intString(eqIdx);
  ty := DAE.T_REAL_DEFAULT;
  resCRef := ComponentReference.makeCrefIdent(resName,ty,{});
  resExp := Expression.makeCrefExp(resCRef,ty);
  resVal := BackendDAE.VAR(resCRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
  (resEq,(resExp,_)) := BackendEquation.traverseBackendDAEExpsEqn(resEq,addResidualVarToEquation2,(resExp,false));
  // update the resEq and resVar lists
  r_i_lst := Debug.bcallret1(List.isEmpty(r_i_lst), List.create, {resVal},varInFrontList(resVal,r_i_lst));
  h_i_lst := Debug.bcallret1(List.isEmpty(h_i_lst), List.create, {resEq}, eqInFrontList(resEq,h_i_lst));
  tplOut := (h_i_lst,r_i_lst);
end addResidualVarToEquation1;


protected function varInFrontList  " puts the varIn at the front of the first list of lists
author: Waurich TUD 2013-08"
  input BackendDAE.Var varIn;
  input list<list<BackendDAE.Var>> lstLstIn;
  output list<list<BackendDAE.Var>> lstLstOut;
algorithm
  lstLstOut := matchcontinue(varIn,lstLstIn)
    local
      list<BackendDAE.Var> varLst;
    case(_,{})
      then
        lstLstIn;
    case(_,_)
      equation
        varLst = List.first(lstLstIn);
        varLst = varIn::varLst;
        lstLstOut = List.replaceAt(varLst,0,lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end varInFrontList;


protected function eqInFrontList  " puts the eqIn at the front of the first list of lists
author: Waurich TUD 2013-08"
  input BackendDAE.Equation eqIn;
  input list<list<BackendDAE.Equation>> lstLstIn;
  output list<list<BackendDAE.Equation>> lstLstOut;
algorithm
  lstLstOut := matchcontinue(eqIn,lstLstIn)
    local
      list<BackendDAE.Equation> eqLst;
    case(_,{})
      then
        lstLstIn;
    case(_,_)
      equation
        eqLst = List.first(lstLstIn);
        eqLst = eqIn::eqLst;
        lstLstOut = List.replaceAt(eqLst,0,lstLstIn);
      then
        lstLstOut;
  end matchcontinue;
end eqInFrontList;


protected function addResidualVarToEquation2 " adds the residual variable to the equation
author: waurich TUD 2013-08"
  input tuple<DAE.Exp,tuple<DAE.Exp,Boolean>> tplIn;
  output tuple<DAE.Exp,tuple<DAE.Exp,Boolean>> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean rhs;
      tuple<DAE.Exp,Boolean> tpl;
      DAE.Exp exp1;
      DAE.Exp exp2;
    case(((exp1,(exp2,rhs))))
      equation
        true = rhs;
        //print("rhs expression: "+&ExpressionDump.dumpExpStr(exp1,0)+&"\n");
        //print("\n append with \n");
        //print("residualValue: "+&ExpressionDump.dumpExpStr(exp2,0)+&"\n");
        exp1 = Expression.expAdd(exp1,exp2);
      then 
        ((exp1,(exp2,true)));
    case(((exp1,(exp2,rhs))))
      equation
        false = rhs;
      then 
        ((exp1,(exp2,true)));
    end matchcontinue;
end addResidualVarToEquation2;


protected function getAlgebraicEquationsForEI "computes from otherEqs the equations to solve for xa_i by:
-replacing (i+1)-times in all otherEqs the tvars with i=0: all tvars=0, i=1: all tvars=0 but tvar{1}=1, i=2: all tvars=0 but tvar{2}=1  etc.
- replacing (i+1)-times in all otherEqs the otherVars(algebraic vars) with $Xai.cref in order to solve for them
author: Waurich TUD 2013-08"
  input list<Integer> iIn;
  input Integer size;
  input list<BackendDAE.Equation> otherEqLstIn;
  input list<BackendDAE.Var> tvarLstIn;
  input list<DAE.ComponentRef> tVarCRefLstIn;
  input list<BackendDAE.Var> otherVarLstIn;
  input list<DAE.ComponentRef> oVarCRefLstIn;
  input list<BackendVarTransform.VariableReplacements> replacementLstIn;
  input list<list<BackendDAE.Equation>> g_i_lstIn;
  input list<list<BackendDAE.Var>> xa_i_lstIn;
  input Integer tornSysIdx;
  output list<list<BackendDAE.Equation>> g_i_lstOut;
  output list<list<BackendDAE.Var>> xa_i_lstOut;
  output list<BackendVarTransform.VariableReplacements> replacementLstOut;
algorithm
  (g_i_lstOut,xa_i_lstOut,replacementLstOut) := matchcontinue(iIn,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn,replacementLstIn,g_i_lstIn,xa_i_lstIn,tornSysIdx)
    local
      Integer iValue;
      String str1,str2;
      list<Integer> iLstRest;
      list<BackendDAE.Equation> gEqLstTmp;
      list<BackendDAE.Var> xaVarLstTmp;
      list<BackendVarTransform.VariableReplacements> replLstTmp;
      list<DAE.ComponentRef> tVarCRefLst1;
      list<list<BackendDAE.Equation>> g_i_lstTmp;
      list<list<BackendDAE.Var>> xa_i_lstTmp;
      BackendDAE.Var tvar;
      BackendVarTransform.VariableReplacements replTmp;
      DAE.ComponentRef tVarCRef;
  case({},_,_,_,_,_,_,_,_,_,_)
    // completed
    equation
      g_i_lstOut = listReverse(g_i_lstIn);
      xa_i_lstOut = listReverse(xa_i_lstIn);
      replacementLstOut = listReverse(replacementLstIn);
    then
      (g_i_lstOut,xa_i_lstOut,replacementLstOut);      
            
  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // get xa_o from g_0
    equation
      true = iValue == 0;
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = List.fold1(tVarCRefLstIn,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,"$xa0"+&intString(tornSysIdx),oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn, replTmp::replacementLstIn, gEqLstTmp::g_i_lstIn,xaVarLstTmp::xa_i_lstIn, tornSysIdx);
    then
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp);
      
  case(iValue::iLstRest,_,_,_,_,_,_,_,_,_,_)
    // computes xa_i from g_i
    equation
      true = iValue > 0;
      str1 = "$xa"+&intString(tornSysIdx)+&intString(iValue);
      str2 = "$g"+&intString(tornSysIdx)+&intString(iValue);
      tVarCRef = listGet(tVarCRefLstIn,iValue);
      tVarCRefLst1 = listDelete(tVarCRefLstIn,iValue-1);
      replTmp = BackendVarTransform.emptyReplacementsSized(size);
      replTmp = replaceTVarWithReal(tVarCRef,1.0,replTmp);
      replTmp = List.fold1(tVarCRefLst1,replaceTVarWithReal,0.0,replTmp);
      ((xaVarLstTmp,replTmp)) = List.fold2(List.intRange(listLength(oVarCRefLstIn)),replaceOtherVarsWithPrefixCref,str1,oVarCRefLstIn,({},replTmp));
      (gEqLstTmp,true) = BackendVarTransform.replaceEquations(otherEqLstIn,replTmp,NONE());
      //BackendVarTransform.dumpReplacements(replTmp);
      //BackendDump.dumpVarList(xaVarLstTmp,str1);
      //BackendDump.dumpEquationList(gEqLstTmp,str2);
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp) = getAlgebraicEquationsForEI(iLstRest,size,otherEqLstIn,tvarLstIn,tVarCRefLstIn,otherVarLstIn,oVarCRefLstIn, replTmp::replacementLstIn, gEqLstTmp::g_i_lstIn,xaVarLstTmp::xa_i_lstIn,tornSysIdx);
    then
      (g_i_lstTmp,xa_i_lstTmp,replLstTmp);
      
  else
    equation
      print("getAlgebraicEquationsForEI1 failed!\n");
    then
      fail();
  end matchcontinue;
end getAlgebraicEquationsForEI;


protected function replaceTVarWithReal "adds the replacement rule to set the tvar to realIn
author: Waurich TUD 2013-08"
  input DAE.ComponentRef tVarCRefIn;
  input Real realIn;
  input BackendVarTransform.VariableReplacements replacementIn;
  output BackendVarTransform.VariableReplacements replacementOut;
algorithm
  replacementOut := BackendVarTransform.addReplacement(replacementIn,tVarCRefIn,DAE.RCONST(realIn),NONE());
end replaceTVarWithReal;


protected function replaceOtherVarsWithPrefixCref "adds the replacement rule to set the cref to $prefix.cref
author: Waurich TUD 2013-07"
  input Integer indxIn; 
  input String prefix;
  input list<DAE.ComponentRef> oVarCRefLstIn;
  input tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplOut;
protected
  list<BackendDAE.Var> replVarLstIn, replVarLstOut;
  BackendDAE.Var replVar;
  BackendVarTransform.VariableReplacements replacementIn,replacementOut;
  DAE.ComponentRef cRef;
  DAE.ComponentRef oVarCRef;
  DAE.Exp varExp;
  DAE.Type ty;
algorithm
  (replVarLstIn,replacementIn) := tplIn;
  oVarCRef := listGet(oVarCRefLstIn,indxIn);
  cRef := ComponentReference.makeCrefQual(prefix,DAE.T_COMPLEX_DEFAULT,{},oVarCRef);
  cRef := ComponentReference.replaceSubsWithString(cRef);
  varExp := Expression.crefExp(cRef);
  replacementOut := BackendVarTransform.addReplacement(replacementIn,oVarCRef,varExp,NONE());
  ty := ComponentReference.crefLastType(cRef);
  replVar := BackendDAE.VAR(cRef,BackendDAE.VARIABLE(),DAE.BIDIR(),DAE.NON_PARALLEL(),ty,NONE(),NONE(),{},DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR());
  replVarLstOut := replVar::replVarLstIn;
  tplOut := (replVarLstOut,replacementOut);
end replaceOtherVarsWithPrefixCref;


protected function dumpVarLstLst "dumps a list<list<BackendDAE.Var>> as a String. TODO: remove when finished
author: Waurich TUD 2013-08"
  input list<list<BackendDAE.Var>> inLstLst;
  input String heading;
protected
  String str;
algorithm
  print("---------\n"+&heading+&"-variables\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpVarLstLst1,inLstLst,heading);
end dumpVarLstLst;


protected function dumpVarLstLst1 "mapping function for dumpVarLstLst  TODO: remove when finished
author: Waurich TUD 2013-08"
  input Integer lstIdx;
  input list<list<BackendDAE.Var>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Var> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+&"_"+&intString(lstIdx-1);
  BackendDump.dumpVarList(inLst,str1); 
  headingOut := heading;
end dumpVarLstLst1;


protected function dumpEqLstLst "dumps a list<list<BackendDAE.Equation>> as a String.  TODO: remove when finished
author: Waurich TUD 2013-08"
  input list<list<BackendDAE.Equation>> inLstLst;
  input String heading;
protected
  String str;
algorithm
  print("---------\n"+&heading+&"-equations\n---------\n");
  str := List.fold1(List.intRange(listLength(inLstLst)),dumpEqLstLst1,inLstLst,heading);
end dumpEqLstLst;


protected function dumpEqLstLst1 "mapping function for dumpEqLstLst  TODO: remove when finished
author: Waurich TUD 2013-08"
  input Integer lstIdx;
  input list<list<BackendDAE.Equation>> inLstLst;
  input String heading;
  output String headingOut;
protected
  String str1;
  list<BackendDAE.Equation> inLst;
algorithm
  inLst := listGet(inLstLst,lstIdx);
  str1 := heading+&"_"+&intString(lstIdx-1);
  BackendDump.dumpEquationList(inLst,str1); 
  headingOut := heading;
end dumpEqLstLst1;


protected function printPartLinTornInfo "prints information about the partitioning of a linear torn system
author: Waurich TUD 2013-10"
  input list<DAE.ComponentRef> tcrs;
  input list<BackendDAE.Equation> reqns;
  input list<BackendDAE.Equation> otherEqnsLst;
  input list<DAE.ComponentRef> ovcrs;
  input list<list<BackendDAE.Var>> xa_i_lst;
  input list<list<BackendDAE.Equation>> g_i_lst;
  input list<list<BackendDAE.Var>> r_i_lst;
  input list<list<BackendDAE.Equation>> h_i_lst;
  input list<list<BackendDAE.Var>> a_i_lst;
  input list<list<BackendDAE.Equation>> hs_i_lst;
  input list<BackendDAE.Equation> hs;
  input BackendDAE.StrongComponents compsNew;
algorithm
   print("disassemble a linear torn system\n");
   print("tvars:\n");
   print(ComponentReference.printComponentRefListStr(tcrs)+&"\n");
   print("resEqs:\n");
   BackendDump.printEquationList(reqns);
   print("otherEqs:\n");
   BackendDump.printEquationList(otherEqnsLst);
   print("other vars:\n");
   print(ComponentReference.printComponentRefListStr(ovcrs)+&"\n");
   dumpVarLstLst(xa_i_lst,"xa");
   dumpEqLstLst(g_i_lst,"g");
   dumpVarLstLst(r_i_lst,"r");
   dumpEqLstLst(h_i_lst,"h");
   dumpVarLstLst(a_i_lst,"a");
   dumpEqLstLst(hs_i_lst,"hs_i");
   BackendDump.dumpEquationList(hs,"hs");
   print("components to get the A-matrix\n");
   BackendDump.dumpComponents(compsNew);
   print("\n");  
end printPartLinTornInfo;


//--------------------------------------------------//
// functions to simplify the generated equations
//-------------------------------------------------//

protected function simplifyEquations "removes simpleEquations like a=0 and replaces variables from equations like a=b, without holding them in the knownvars or aliasvars
author: Waurich TUD 2013-10"
  input list<list<BackendDAE.Equation>> eqLstLstIn;
  input list<list<BackendDAE.Var>> varLstLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<list<BackendDAE.Equation>> eqLstLstOut;
  output list<list<BackendDAE.Var>> varLstLstOut;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  ((eqLstLstOut,varLstLstOut,replOut)) := List.fold(List.intRange(listLength(eqLstLstIn)),simplifyEquations1,(eqLstLstIn,varLstLstIn,replIn));  
  //(eqLstLstOut,varLstLstOut,replOut) := (eqLstLstIn,varLstLstIn,replIn); 
end simplifyEquations;


protected function simplifyEquations1 "implementation for simplifyEquations. traverses a list of the list<list<equation>>"
  input Integer idx;
  input tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<list<BackendDAE.Equation>>,list<list<BackendDAE.Var>>,BackendVarTransform.VariableReplacements> tplOut;
protected
  BackendVarTransform.VariableReplacements repl;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<list<BackendDAE.Equation>> eqLstLst;
  list<list<BackendDAE.Var>> varLstLst;
algorithm 
  (eqLstLst,varLstLst,repl) := tplIn;
  eqLst := listGet(eqLstLst,idx);
  varLst := listGet(varLstLst,idx);
  // remove all vars that are assigned to a constant or alias, remove the equations, update the replacement rule
  ((eqLst,varLst,repl)) := simplifyEquations2((eqLst,varLst,repl));
  eqLstLst := List.replaceAt(eqLst,idx-1,eqLstLst);
  varLstLst := List.replaceAt(varLst,idx-1,varLstLst);
  tplOut := ((eqLstLst,varLstLst,repl));
end simplifyEquations1;


protected function simplifyEquations2 "repeats the simplification until nothing changed anymore"
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplOut;
algorithm
  tplOut := matchcontinue(tplIn)
    local
      Boolean changed;
      BackendVarTransform.VariableReplacements repl, replIn;
      list<BackendDAE.Equation> eqLst, eqLstIn;
      list<BackendDAE.Var> varLst, varLstIn;
    case((eqLstIn,varLstIn,replIn))
      equation
        ((varLst,eqLst,repl,changed)) = removeConstOrAlias(1,(varLstIn,eqLstIn,replIn,false));
        true = changed;
        (eqLst,_) = BackendVarTransform.replaceEquations(eqLst,repl,NONE());
        ((eqLst,varLst,repl)) = simplifyEquations2((eqLst,varLst,repl));
      then
        ((eqLst,varLst,repl));
    case((eqLstIn,varLstIn,replIn))
      equation
        ((varLst,eqLst,repl,changed)) = removeConstOrAlias(1,(varLstIn,eqLstIn,replIn,false));
        false = changed;
        (eqLst,_) = BackendVarTransform.replaceEquations(eqLst,repl,NONE());
      then
        ((eqLst,varLst,repl));
    else
      equation
        print("simplifyEquations2 failed!\n");
      then
        fail();
  end matchcontinue;
end simplifyEquations2; 


protected function removeConstOrAlias "removes the equations and vars for which vars are assigned to constants or alias and replaces them.
author: Waurich TUD 2013-10"
  input Integer eqIdx;
  input tuple<list<BackendDAE.Var>, list<BackendDAE.Equation>, BackendVarTransform.VariableReplacements,Boolean> tplIn;
  output tuple<list<BackendDAE.Var>, list<BackendDAE.Equation>, BackendVarTransform.VariableReplacements,Boolean> tplOut;
algorithm
  tplOut := matchcontinue(eqIdx,tplIn)
    local
      Boolean b, changed, changed1;
      Integer eqIdxTmp;
      BackendDAE.Equation eq;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl,replIn;
      DAE.ComponentRef varCref;
      DAE.Exp varExp, const, exp1, exp2;
      list<BackendDAE.Equation>  eqLst, eqLstIn;
      list<BackendDAE.Var> varLst, varLstIn;
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      true = listLength(eqLstIn) < eqIdx;
    then
      tplIn;
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      //one side of the equation is constant
      eq = listGet(eqLstIn,eqIdx);
      (b,SOME((varExp,const))) = oneSideConstant(eq);
      true = b;
      //print("\neq with const: "+&BackendDump.dumpEqnsStr({eq})+&"\n");
      //print("one side is constant\n");
      (eqLst,varLst,repl,changed1) = handleConstantSide(varExp,const,eqIdx,eqLstIn,varLstIn,replIn,changed);
      eqIdxTmp = Util.if_(changed1, eqIdx, eqIdx+1);
      changed = changed1 or changed;
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdxTmp,(varLst,eqLst,repl,changed));
    then
      ((varLst,eqLst,repl,changed));
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      //both sides of the equation are crefs
      eq = listGet(eqLstIn,eqIdx);
      BackendDAE.EQUATION(exp= exp1, scalar=exp2) = eq;
      true = Expression.isCref(exp1);
      true = Expression.isCref(exp2);
      //print("\neq with both sides CREFs: "+&BackendDump.dumpEqnsStr({eq})+&"\n");
      (eqLst,varLst,repl,changed1) = checkForPosAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      eqIdxTmp = Util.if_(changed1, eqIdx, eqIdx+1);
      changed = changed1 or changed;
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdxTmp,(varLst,eqLst,repl,changed));
    then
      ((varLst,eqLst,repl,changed));
  case(_,(varLstIn,eqLstIn,replIn,changed))
    equation
      // nothing to simplify. go to next equation
      //print("nothing to simplify\n");
      //print("changed? "+&boolString(changed)+&"\n");
      ((varLst,eqLst,repl,changed)) = removeConstOrAlias(eqIdx+1,(varLstIn,eqLstIn,replIn,changed));
    then
      ((varLst,eqLst,repl,changed));
    else
      equation
        print("removeConstOrAlias failed!\n");
      then 
        fail();
  end matchcontinue;
end removeConstOrAlias;           
      
      
protected function handleConstantSide "checks if the equation is a constant assignment i.e. a=const, const=a or a simple equation i.e. a+b=0
author: Waurich TUD 2013-10"
  input DAE.Exp varExp;
  input DAE.Exp constExp;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  input Boolean changedIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changedOut;
algorithm
  (eqLstOut,varLstOut,replOut,changedOut) := matchcontinue(varExp,constExp,eqIdx,eqLstIn,varLstIn,replIn,changedIn)
    local
      Boolean changed;
      Real real;
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref;
      DAE.Exp exp1,exp2;
      DAE.Operator op;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref),DAE.RCONST(real=real),_,_,_,_,_)
      equation
        // check for simple equations: a = const.
        vars = BackendVariable.listVar(varLstIn);
        vars = BackendVariable.removeCref(cref,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = listDelete(eqLstIn, eqIdx-1);
        repl = BackendVarTransform.addReplacement(replIn,cref,constExp,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.BINARY(exp1=exp1,operator=op,exp2=exp2),DAE.RCONST(real=real),_,_,_,_,_)
      equation
        // check for alias vars: a+-b = 0.0
        true = real ==. 0.0;
        (eqLst,varLst,repl,changed) = checkForAlias(exp1,exp2,op,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);        
  end matchcontinue;
end handleConstantSide;
      

protected function checkForAlias "checks if the there are alias variables for the new vars from varLstIn.
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.Operator op;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changedOut;
algorithm
  (eqLstOut,varLstOut,replOut,changedOut) := matchcontinue(exp1,exp2,op,eqIdx,eqLstIn,varLstIn,replIn)
    local
      Boolean changed;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(_,_,DAE.ADD(_),_,_,_,_)
      equation
        true = Expression.isCref(exp1);
        true = Expression.isCref(exp2);
        // a + otherVar = 0  replace: a--> -otherVar   or   a + b = 0 replace: a --> -b
        (eqLst,varLst,repl,changed) = checkForNegAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    case(_,_,DAE.SUB(_),_,_,_,_)
      equation
        true = Expression.isCref(exp1);
        true = Expression.isCref(exp2);
        // a - otherVar = 0  replace: a--> otherVar   or   a - b = 0 replace: a --> b
        (eqLst,varLst,repl,changed) = checkForPosAlias(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn);
      then
        (eqLst,varLst,repl,changed);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end checkForAlias;


protected function checkForNegAlias "checks if there are variables that can be replaced from a+otherVar = 0  to  a --> -otherVar. a has to be in the varLstIn
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changed;
algorithm
  (eqLstOut,varLstOut,replOut,changed) := matchcontinue(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      DAE.Exp newExp;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // a + otherVar = 0  replace: a --> -otherVar   or   a + b = 0 replace: a --> -b
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = listDelete(eqLstIn, eqIdx-1);
        newExp = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp2);
        //print("checkForNegAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with "+&ExpressionDump.printExpStr(newExp)+&"\n");
        repl = BackendVarTransform.addReplacement(replIn,cref1,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // otherVar + a = 0  replace: a --> -otherVar 
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref2,vars,false);
        vars = BackendVariable.removeCref(cref2,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = listDelete(eqLstIn, eqIdx-1);
        newExp = DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),exp1);
        //print("checkForNegAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with - "+&ExpressionDump.printExpStr(newExp)+&"\n");
        repl = BackendVarTransform.addReplacement(replIn,cref2,newExp,NONE());
      then
        (eqLst,varLst,repl,true);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end checkForNegAlias;


protected function checkForPosAlias"checks if there are variables that can be replaced from a-otherVar = 0  to  a --> otherVar. a has to be in the varLstIn
author: Waurich TUD 2013-10"
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input Integer eqIdx;
  input list<BackendDAE.Equation> eqLstIn;
  input list<BackendDAE.Var> varLstIn;
  input BackendVarTransform.VariableReplacements replIn;
  output list<BackendDAE.Equation> eqLstOut;
  output list<BackendDAE.Var> varLstOut;
  output BackendVarTransform.VariableReplacements replOut;
  output Boolean changed;
algorithm
  (eqLstOut,varLstOut,replOut,changed) := matchcontinue(exp1,exp2,eqIdx,eqLstIn,varLstIn,replIn)
    local
      BackendDAE.Variables vars;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cref1,cref2;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.Var> varLst;
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // a - otherVar = 0  replace: a --> otherVar   or   a - b = 0 replace: a --> b
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref1,vars,false);
        //print("checkForPosAlias: replace "+&ComponentReference.printComponentRefStr(cref1)+&" with "+&ExpressionDump.printExpStr(exp2)+&"\n");
        vars = BackendVariable.removeCref(cref1,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = listDelete(eqLstIn, eqIdx-1);
        repl = BackendVarTransform.addReplacement(replIn,cref1,exp2,NONE());
      then
        (eqLst,varLst,repl,true);
    case(DAE.CREF(componentRef = cref1),DAE.CREF(componentRef = cref2),_,_,_,_)
      equation
        // otherVar - a = 0  replace: a --> otherVar 
        vars = BackendVariable.listVar(varLstIn);
        true = BackendVariable.existsVar(cref2,vars,false);
        //print("checkForPosAlias: replace "+&ComponentReference.printComponentRefStr(cref2)+&" with "+&ExpressionDump.printExpStr(exp1)+&"\n");
        vars = BackendVariable.removeCref(cref2,vars);
        varLst = BackendVariable.varList(vars);
        eqLst = listDelete(eqLstIn, eqIdx-1);
        repl = BackendVarTransform.addReplacement(replIn,cref2,exp1,NONE());
      then
        (eqLst,varLst,repl,true);
    else
      equation
      then
        (eqLstIn,varLstIn,replIn,false);
  end matchcontinue;
end checkForPosAlias;


protected function oneSideConstant "checks whether the given equation has one side with a constant.
author: Waurich TUD 2013-07"
  input BackendDAE.Equation eqIn;
  output Boolean hasConst;
  output Option<tuple<DAE.Exp,DAE.Exp>> varExp;  //<non-constant side, constant side>
algorithm
  (hasConst,varExp) := matchcontinue(eqIn)
    local
      DAE.Exp lhs,rhs;
    case(BackendDAE.EQUATION(exp = rhs, scalar = lhs))
      equation
        true = Expression.isConst(lhs);
      then
        (true,SOME((rhs,lhs)));
    case(BackendDAE.EQUATION(exp = rhs, scalar = lhs))
      equation
        true = Expression.isConst(rhs);
      then
        (true,SOME((lhs,rhs)));
    else
      equation
      then
        (false,NONE());
  end matchcontinue;  
end oneSideConstant;

//--------------------------------------------------//
// 
//-------------------------------------------------//

end HpcOmSimCode;