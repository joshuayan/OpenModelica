/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

package Derive
" file:        Derive.mo
  package:     Derive
  description: Differentiation of equations from BackendDAE.BackendDAE

  RCS: $Id$

  This module is responsible for symbolic differentiation of equations and
  expressions. Is is currently (2004-09-28) only used by the solve function in
  the exp module for solving equations.

  The symbolic differentiation is used in the Newton-Raphson method and in
  index reduction."

// public imports
public import Absyn;
public import BackendDAE;
public import Builtin;
public import DAE;
public import DAEUtil;
public import RTOpts;
public import Types;

// protected imports
protected import BackendDAECreate;
protected import BackendVariable;
protected import ComponentReference;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import Inline;
protected import Util;

public function differentiateEquationTime "function: differentiateEquationTime
  Differentiates an equation with respect to the time variable."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input DAE.FunctionTree inFunctions;
  input array<DAE.Algorithm> al;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiEqn;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outal;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output array<BackendDAE.MultiDimEquation> outArrayEqs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output Boolean outAdd;
algorithm
  (outEquation,outal,outDerivedAlgs,outArrayEqs,outDerivedMultiEqn,outAdd) := matchcontinue (inEquation,inVariables,inFunctions,al,inDerivedAlgs,inMultiEqn,inDerivedMultiEqn)
    local
      DAE.Exp e1_1,e2_1,e1_2,e2_2,e1,e2;
      BackendDAE.Variables timevars;
      BackendDAE.Equation dae_equation;
      DAE.ElementSource source,source1,sourceStmt;
      Absyn.Path p;
      DAE.FunctionDefinition mapper;
      DAE.Type tp;
      Integer index,i_1,index1;
      list<DAE.Exp> in_,din_,in_1,out,out1,dout,dout1,expExpLst,expExpLst1; 
      list<Boolean> blst; 
      DAE.ExpType exptyp;
      list<DAE.ExpType> exptyplst; 
      array<DAE.Algorithm> a1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedMultiEqn;
      Boolean add;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<BackendDAE.MultiDimEquation> listae,listae1;
      list<DAE.Exp> crefOrDerCref,crefOrDerCref1,crefOrDerCref11,crefOrDerCref2,crefOrDerCref21,crefOrDerCref3,derCref1,derCref2;
      list<Integer> dimSize;
    
    // equations
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source=source),timevars,inFunctions,al,inDerivedAlgs,ae,inDerivedMultiEqn) /* time varying variables */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,inFunctions));
        e2_1 = differentiateExpTime(e2, (timevars,inFunctions));
        e1_2 = ExpressionSimplify.simplify(e1_1);
        e2_2 = ExpressionSimplify.simplify(e2_1);
      then
        (BackendDAE.EQUATION(e1_2,e2_2,source),al,inDerivedAlgs,ae,inDerivedMultiEqn,true);
    
    // complex equations
    case (BackendDAE.COMPLEX_EQUATION(index = index,lhs=e1,rhs=e2,source=source),timevars,inFunctions,al,inDerivedAlgs,ae,inDerivedMultiEqn)
      equation
        true = intEq(index,-1);
        e1_1 = differentiateExpTime(e1, (timevars,inFunctions));
        e2_1 = differentiateExpTime(e2, (timevars,inFunctions));
        // e1_2 = ExpressionSimplify.simplify(e1_1);
        // e2_2 = ExpressionSimplify.simplify(e2_1);
       then
        // because der(Record) is not jet implemented -> fail()
        //(BackendDAE.COMPLEX_EQUATION(index,e1_1,e2_1,source),al,inDerivedAlgs,ae,inDerivedMultiEqn,true);
        fail();
   
    // Array Equations    
    case (BackendDAE.ARRAY_EQUATION(index = index,crefOrDerCref=crefOrDerCref,source=source),timevars,inFunctions,al,inDerivedAlgs,ae,inDerivedMultiEqn)
      equation
        // get Equation
        i_1 = index+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i_1];
        e1_1 = differentiateExpTime(e1, (timevars,inFunctions));
        e2_1 = differentiateExpTime(e2, (timevars,inFunctions));
        e1_2 = ExpressionSimplify.simplify(e1_1);
        e2_2 = ExpressionSimplify.simplify(e2_1);
        ((_,(crefOrDerCref1,derCref1,_))) = Expression.traverseExp(e1_2,traversingcrefOrDerCrefFinder,({},{},timevars));
        ((_,(crefOrDerCref2,derCref2,_))) = Expression.traverseExp(e2_2,traversingcrefOrDerCrefFinder,({},{},timevars));
        crefOrDerCref11 = removeCrefFromDerCref(crefOrDerCref1,derCref1);
        crefOrDerCref21 = removeCrefFromDerCref(crefOrDerCref2,derCref2);
        crefOrDerCref3 = Util.listUnionOnTrue(crefOrDerCref11,crefOrDerCref21,Expression.expEqual);
        // only add algorithm if it is not already derived 
        (index1,ae1,derivedMultiEqn,add) = addArray(index,ae,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_2,e2_2,source1),1,inDerivedMultiEqn);
       then
        //(BackendDAE.ARRAY_EQUATION(index1,{e1_1},source),al,inDerivedAlgs,ae1,derivedMultiEqn,add);
         // Until the array equations will be unrolled we should return true to add an equation for every element
        (BackendDAE.ARRAY_EQUATION(index1,crefOrDerCref3,source),al,inDerivedAlgs,ae1,derivedMultiEqn,true);
    
    // diverivative of function with multiple outputs
    case (BackendDAE.ALGORITHM(index = index,in_=in_,out=out,source=source),timevars,inFunctions,al,inDerivedAlgs,ae,inDerivedMultiEqn)
      equation
        // get Allgorithm
        DAE.ALGORITHM_STMTS(statementLst= {DAE.STMT_TUPLE_ASSIGN(type_=exptyp,expExpLst=expExpLst,exp = e1,source=sourceStmt)}) = al[index+1];
        e1_1 = differentiateFunctionTime(e1,(timevars,inFunctions));
        e1_2 = Inline.inlineExp(e1_1,(SOME(inFunctions),{DAE.NORM_INLINE()}));
        e2 = ExpressionSimplify.simplify(e1_2);
        // outputs
        (expExpLst1,out1) = differentiateFunctionTimeOutputs(e1,e2,expExpLst,out,(timevars,inFunctions));
        // inputs
        ((in_1,_)) = BackendDAECreate.lowerAlgorithmInputsOutputs(timevars,DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exptyp,expExpLst1,e2,sourceStmt)}));
        // only add algorithm if it is not already derived 
        (index,a1,derivedAlgs,add) = addArray(index,al,DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(exptyp,expExpLst1,e2,sourceStmt)}),listLength(out1),inDerivedAlgs);
       then
        (BackendDAE.ALGORITHM(index,in_1,out1,source),a1,derivedAlgs,ae,inDerivedMultiEqn,add);
    
    case (BackendDAE.COMPLEX_EQUATION(index = _),_,_,_,_,_,_)
      equation
        print("- Derive.differentiateEquationTime on complex equations not impl yet.\n");
      then
        fail();
    
    case (BackendDAE.ARRAY_EQUATION(index = _),_,_,_,_,_,_)
      equation
        print("- Derive.differentiateEquationTime on array equations not impl yet.\n");
      then
        fail();
    
    case (BackendDAE.ALGORITHM(index = _),_,_,_,_,_,_)
      equation
        print("- Derive.differentiateEquationTime on algorithm not impl yet.\n");
      then
        fail();
    
    case (dae_equation,_,_,_,_,_,_)
      equation
        print("- Derive.differentiateEquationTime failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEquationTime;

protected function removeCrefFromDerCref "
Author: Frenkel TUD"
  input list<DAE.Exp> inCrefOrDerCref;
  input list<DAE.Exp> inDerCref;
  output list<DAE.Exp> outCrefOrDerCref;
algorithm 
  outCrefOrDerCref := matchcontinue(inCrefOrDerCref,inDerCref)
    local
      list<DAE.Exp> rest,crefOrDerCref,crefOrDerCref1;
      DAE.Exp e;
    
    case (inCrefOrDerCref,{}) then inCrefOrDerCref;
    
    case (inCrefOrDerCref,e::rest)
      equation
        crefOrDerCref = removeCrefFromDerCref(inCrefOrDerCref,rest);
        crefOrDerCref1 = Util.listDeleteMemberOnTrue(crefOrDerCref,e,Expression.expEqual);
      then
        crefOrDerCref1;
  end matchcontinue;
end removeCrefFromDerCref;

protected function traversingcrefOrDerCrefFinder "
Author: Frenkel TUD
Returns a list containing, unique, all componentRef or der(componentRef) in an Expression."
  input tuple<DAE.Exp, tuple<list<DAE.Exp>,list<DAE.Exp>,BackendDAE.Variables> > inExp;
  output tuple<DAE.Exp, tuple<list<DAE.Exp>,list<DAE.Exp>,BackendDAE.Variables> > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      list<DAE.Exp> crefOrDerCref,derCref;
      DAE.Exp e,e1;
      BackendDAE.Variables timevars;
      DAE.ComponentRef cr;
  
    // CREF
    case( (e as DAE.CREF(componentRef = cr), (crefOrDerCref,derCref,timevars)) )
      equation
        // exlude time
        failure(DAE.CREF_IDENT(ident = "time",subscriptLst = {}) = cr);
        (_,_) = BackendVariable.getVar(cr, timevars);
      then
        ((e, (e::crefOrDerCref,derCref,timevars) ));
    
    // der(CREF)    
    case ( (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={e1 as DAE.CREF(componentRef = cr)}), (crefOrDerCref,derCref,timevars)) )
      equation
        (_,_) = BackendVariable.getVar(cr, timevars);
      then
        ((e, (e::crefOrDerCref,e1::derCref,timevars) ));
    
    // der(der(CREF))
    case ( (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={e1 as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef = cr)})}), (crefOrDerCref,derCref,timevars)) )
      equation
        (_,_) = BackendVariable.getVar(cr, timevars);
      then
        ((e, (e::crefOrDerCref,e1::derCref,timevars) ));      
    
    case(inExp) then inExp;
  end matchcontinue;
end traversingcrefOrDerCrefFinder;

protected function addArray "
Author: Frenkel TUD"
  input Integer inIndex;
  input array<Type_a> inArray;
  input Type_a inA;
  input Integer inNumber;
  input list<tuple<Integer,Integer,Integer>> inDerivedArray;   
  output Integer outIndex;
  output array<Type_a> outArray; 
  output list<tuple<Integer,Integer,Integer>> outDerivedArray;
  output Boolean outAdd;
  replaceable type Type_a subtypeof Any;
algorithm
  (outIndex,outArray,outDerivedArray,outAdd) := matchcontinue (inIndex,inArray,inA,inNumber,inDerivedArray)
    local
      list<tuple<Integer,Integer,Integer>> rest,derivedArray;
      tuple<Integer,Integer,Integer> dArray;
      list<Type_a> alst,alst1;
      Integer index,index1,dindex,dnumber,dnumber_1;
      array<Type_a> a1;
      Boolean add;
   // no derived functions without outputs
   case (inIndex,inArray,inA,inNumber,derivedArray)
     equation
       true = intEq(inNumber,0); 
     then
       (inIndex,inArray,derivedArray,false);      
   // not derived   
   case (inIndex,inArray,inA,inNumber,{})
     equation
        alst = arrayList(inArray);
        alst1 = listAppend(alst,{inA});
        a1 = listArray(alst1);
        index = arrayLength(inArray);      
     then
       (index,a1,{(inIndex,index,1)},true);
   // derived    
   case (inIndex,inArray,inA,inNumber,(dArray as (index,dindex,dnumber))::rest)
     equation
       // search
       true = intEq(inIndex,index);
       true = dnumber < inNumber;
       dnumber_1 = dnumber + 1;
     then
       (dindex,inArray,(index,dindex,dnumber_1)::rest,true);    
   case (inIndex,inArray,inA,inNumber,(dArray as (index,dindex,dnumber))::rest)
     equation
       // search
       true = intEq(inIndex,index);
       false = dnumber < inNumber;
     then
       (dindex,inArray,(index,dindex,dnumber)::rest,false);        
   case (inIndex,inArray,inA,inNumber,(dArray as (index,dindex,dnumber))::rest)
     equation
       false = intEq(inIndex,index);
       // next
       (index1,a1,derivedArray,add) = addArray(inIndex,inArray,inA,inNumber,rest);
     then   
       (index1,a1,dArray::derivedArray,add);    
  end matchcontinue;
end addArray;

public function differentiateExpTime "function: differentiateExpTime
  This function differentiates expressions with respect to the \'time\' variable.
  All other variables that are varying over time are given as the second variable.
  For instance, given the model:
  model test
    Real x,y;
    parameter Real PI=3.14;
  equation
    x+y=5PI;
  end test;
  gives
  differentiate_exp_time(\'x+y=5PI\', {x,y}) => der(x)+der(y)=0"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVariables;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inVariables)
    local
      DAE.ExpType tp;      
      DAE.ComponentRef cr;
      String cr_str,cr_str_1,e_str,str,s1;
      DAE.Exp e,e_1,e1_1,e2_1,e1,e2,e3_1,e3,d_e1,exp,e0;
      BackendDAE.Variables timevars;
      DAE.Operator op,rel;
      list<DAE.Exp> expl_1,expl,sub;
      Absyn.Path a;
      Boolean b,c;
      DAE.InlineType inl;
      Integer i;
      Absyn.Path fname;
      DAE.ExpType ty;
      DAE.FunctionTree functions;
      DAE.Element func;
      list<list<tuple<DAE.Exp, Boolean>>> explstlst,explstlst1;

    case (DAE.ICONST(integer = _),_) then DAE.RCONST(0.0);
    case (DAE.RCONST(real = _),_) then DAE.RCONST(0.0);
    
    case (DAE.CREF(componentRef = DAE.CREF_IDENT(ident = "time",subscriptLst = {}),ty = tp),_) 
      then DAE.RCONST(1.0);
    
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions)) /* special rule for DUMMY_STATES, they become DUMMY_DER */
      equation
        ({BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE())},_) = BackendVariable.getVar(cr, timevars);
        cr = ComponentReference.crefPrefixDer(cr);
        e = Expression.makeCrefExp(cr, tp);
      then
        e;

    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions))
      equation
        (_,_) = BackendVariable.getVar(cr, timevars);
      then
        DAE.CALL(Absyn.IDENT("der"),{e},false,true,tp,DAE.NO_INLINE());

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isSin(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(sin(x)) = der(x)cos(x)" ;
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cos"),{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isCos(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(cos(x)) = -der(x)sin(x)" ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

        // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isACos(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

        // der(arcsin(x)) = der(x)/sqrt(1-x^2)
      case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isASin(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

        // der(arctan(x)) = der(x)/1+x^2
      case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isATan(fname);
        e_1 = differentiateExpTime(e, (timevars,functions))  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));

        // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
      case (DAE.CALL(path = fname,expLst = {e,e1}),(timevars,functions))
      equation
        Builtin.isATan2(fname);
        true = Expression.isZero(e1);
        (exp,_) = Expression.makeZeroExpression({});
      then
       exp;

        // der(arctan2(y,x)) = der(y/x)/1+(y/x)^2
      case (DAE.CALL(path = fname,expLst = {e,e1}),(timevars,functions))
      equation
        Builtin.isATan2(fname);
        false = Expression.isZero(e1);
        exp = Expression.makeDiv(e,e1);
        e_1 = differentiateExpTime(exp, (timevars,functions));
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));

    case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isExp(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(exp(x)) = der(x)exp(x)" ;
      then
        DAE.BINARY(e_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(fname,{e},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

        case (DAE.CALL(path = fname,expLst = {e}),(timevars,functions))
      equation
        Builtin.isLog(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(log(x)) = der(x)/x";
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),e);

    case (DAE.CALL(path = fname,expLst = {e},tuple_ = false,builtin = true),(timevars,functions))
      equation
        Builtin.isLog(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "der(log(x)) = der(x)/x" ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),e);

    case (DAE.CALL(path = fname,expLst = expl,tuple_=false,builtin = true,ty=tp,inlineType=inl),(timevars,functions))
      equation
        Builtin.isMax(fname);
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.CALL(fname,expl_1,false,true,tp,inl);

    case (DAE.CALL(path = fname,expLst = expl,tuple_=false,builtin = true,ty=tp,inlineType=inl),(timevars,functions))
      equation
        Builtin.isMin(fname);
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.CALL(fname,expl_1,false,true,tp,inl);

    case (e0 as DAE.CALL(path = fname,expLst = {e},tuple_=false,builtin = true,ty=tp,inlineType=inl),(timevars,functions))
      equation
        Builtin.isSqrt(fname);
        e_1 = differentiateExpTime(e, (timevars,functions)) "sqrt(x) = der(x)/(2*sqrt(x))" ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),e0));

    case (DAE.CALL(path = fname,expLst = {e1,e2},tuple_=false,builtin = true,ty=tp,inlineType=inl),(timevars,functions))
      equation
        Builtin.isCross(fname);
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.CALL(fname,{e1,e2_1},false,true,tp,inl),DAE.ADD_ARR(tp),DAE.CALL(fname,{e1_1,e2},false,true,tp,inl));

    case (DAE.CALL(path = fname,expLst = expl,tuple_=false,builtin = true,ty=tp,inlineType=inl),(timevars,functions))
      equation
        Builtin.isTranspose(fname);
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.CALL(fname,expl_1,false,true,tp,inl);

    case (e0 as DAE.BINARY(exp1 = e1,operator = DAE.POW(tp),exp2 = (e2 as DAE.RCONST(_))),(timevars,functions)) /* ax^(a-1) */
      equation
        d_e1 = differentiateExpTime(e1, (timevars,functions)) "e^x => xder(e)e^x-1" ;
        // false = Expression.expContains(e2, Expression.makeCrefExp(tv,tp));
        // const_one = differentiateExp(Expression.makeCrefExp(tv,tp), tv);
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),DAE.RCONST(1.0))));
      then
        exp;

    case ((e as DAE.CREF(componentRef = cr,ty = tp as DAE.ET_ARRAY(arrayDimensions=_))),(timevars,functions)) /* list_member(cr,timevars) => false */ 
      equation
         // generate zeros
         expl_1 = Util.listFill(DAE.RCONST(0.0), Expression.sizeOf(tp));  
      then DAE.ARRAY(tp,true,expl_1);
    
    case ((e as DAE.CREF(componentRef = cr,ty = tp)),(timevars,functions)) 
      then DAE.RCONST(0.0);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),(timevars,functions)) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),(timevars,functions)) /* (f\'g - fg\' ) / g^2 */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(
          DAE.BINARY(DAE.BINARY(e1_1,DAE.MUL(tp),e2),DAE.SUB(tp),
          DAE.BINARY(e1,DAE.MUL(tp),e2_1)),DAE.DIV(tp),DAE.BINARY(e2,DAE.MUL(tp),e2));
    
    case (DAE.UNARY(operator = op,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.UNARY(op,e_1);
    
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),(timevars,functions))
      equation
        e_str = ExpressionDump.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    
    case (DAE.LUNARY(operator = op,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.LUNARY(op,e_1);
    
    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.RELATION(e1_1,rel,e2_1);
    
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),(timevars,functions))
      equation
        e2_1 = differentiateExpTime(e2, (timevars,functions));
        e3_1 = differentiateExpTime(e3, (timevars,functions));
      then
        DAE.IFEXP(e1,e2_1,e3_1);
    
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst = expl,tuple_ = b,builtin = c,ty=tp,inlineType=inl),(timevars,functions))
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.CALL(a,expl_1,b,c,tp,inl);
    
    case (e as DAE.CALL(path = a,expLst = expl,tuple_ = b,builtin = c),(timevars,functions))
      equation
        // get Derivative function
        e1 = differentiateFunctionTime(e,(timevars,functions));
        e2 = Inline.inlineExp(e1,(SOME(functions),{DAE.NORM_INLINE()}));
      then
        e2;        
    
    case (e as DAE.CALL(path = a,expLst = expl,tuple_ = b,builtin = c),(timevars,functions))
      equation
        e_str = ExpressionDump.printExpStr(e);
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    
    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),(timevars,functions))
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.ARRAY(tp,b,expl_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.ADD_ARR(tp),e2_1);    
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.SUB_ARR(tp),e2_1);  
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = tp),exp2 = e2),(timevars,functions)) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARR(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_ARR(tp),e2));    
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_SCALAR_ARRAY(ty = tp),exp2 = e2),(timevars,functions)) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_SCALAR_ARRAY(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_SCALAR_ARRAY(tp),e2));  
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = tp),exp2 = e2),(timevars,functions)) /* f\'g + fg\' */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2_1),DAE.ADD_ARR(tp),
          DAE.BINARY(e1_1,DAE.MUL_ARRAY_SCALAR(tp),e2));     
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_SCALAR_ARRAY(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.ADD_SCALAR_ARRAY(tp),e2_1); 
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.ADD_ARRAY_SCALAR(tp),e2_1);  
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.SUB_SCALAR_ARRAY(tp),e2_1);  
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARRAY_SCALAR(ty = tp),exp2 = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(e1_1,DAE.SUB_ARRAY_SCALAR(tp),e2_1);      
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = tp),exp2 = e2),(timevars,functions)) /* (f\'g - fg\' ) / g^2 */
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.BINARY(
          DAE.BINARY(DAE.BINARY(e1_1,DAE.MUL_ARRAY_SCALAR(tp),e2),DAE.SUB_ARR(tp),
          DAE.BINARY(e1,DAE.MUL_ARRAY_SCALAR(tp),e2_1)),DAE.DIV_ARRAY_SCALAR(tp),DAE.BINARY(e2,DAE.MUL(tp),e2));                                                               
    
    case ((e as DAE.MATRIX(ty = tp,integer=i,scalar=explstlst)),(timevars,functions))
      equation
        explstlst1 = differentiateMatrixTime(explstlst,(timevars,functions));
      then
        DAE.MATRIX(tp,i,explstlst1);
    
    case (DAE.TUPLE(PR = expl),(timevars,functions))
      equation
        expl_1 = Util.listMap1(expl, differentiateExpTime, (timevars,functions));
      then
        DAE.TUPLE(expl_1);
    
    case (DAE.CAST(ty = tp,exp = e),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        DAE.CAST(tp,e_1);
    
    case (DAE.ASUB(exp = e,sub = sub),(timevars,functions))
      equation
        e_1 = differentiateExpTime(e, (timevars,functions));
      then
        Expression.makeASUB(e,sub);
    
    case (DAE.REDUCTION(path = a,expr = e1,ident = str,range = e2),(timevars,functions))
      equation
        e1_1 = differentiateExpTime(e1, (timevars,functions));
        e2_1 = differentiateExpTime(e2, (timevars,functions));
      then
        DAE.REDUCTION(a,e1_1,str,e2_1);
    
    case (e,_)
      equation
        str = ExpressionDump.printExpStr(e);
        print("- Derive.differentiateExpTime on ");
        print(str);
        print(" failed\n");
      then
        fail();
  end matchcontinue;
end differentiateExpTime;

protected function differentiateMatrixTime
"function: differentiateMatrixTime
  author: Frenkel TUD
   Helper function to differentiateExpTime, differentiate matrix expressions."
  input list<list<tuple<DAE.Exp, Boolean>>> inTplExpBooleanLstLst;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVariables;
  output list<list<tuple<DAE.Exp, Boolean>>> outTplExpBooleanLstLst;
algorithm
  outTplExpBooleanLstLst := matchcontinue (inTplExpBooleanLstLst,inVariables)
    local
      list<tuple<DAE.Exp, Boolean>> row_1,row;
      list<list<tuple<DAE.Exp, Boolean>>> rows_1,rows;
    
    case ({},_) then ({});
    
    case ((row :: rows),inVariables)
      equation
        row_1 = differentiateMatrixTime1(row, inVariables);
        rows_1 = differentiateMatrixTime(rows, inVariables);
      then
        (row_1 :: rows_1);
  end matchcontinue;
end differentiateMatrixTime;

protected function differentiateMatrixTime1
"function: traverseExpMatrix2
  author: Frenkel TUD
  Helper function to differentiateMatrixTime."
  input list<tuple<DAE.Exp, Boolean>> inTplExpBooleanLst;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVariables;
  output list<tuple<DAE.Exp, Boolean>> outTplExpBooleanLst;
algorithm
  outTplExpBooleanLst := matchcontinue (inTplExpBooleanLst,inVariables)
    local
      DAE.Exp e_1,e;
      list<tuple<DAE.Exp, Boolean>> rest_1,rest;
      Boolean b;
    
    case ({},_) then ({});
    
    case (((e,b) :: rest),inVariables)
      equation
        e_1 = differentiateExpTime(e, inVariables);
        rest_1 = differentiateMatrixTime1(rest, inVariables);
      then
        ((e_1,b) :: rest_1);
  end matchcontinue;
end differentiateMatrixTime1;

protected function differentiateFunctionTimeOutputs"
Author: Frenkel TUD"
  input DAE.Exp inExp;
  input DAE.Exp inDExp;
  input list<DAE.Exp> inExpLst;
  input list<DAE.Exp> inExpLst1;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVarsandFuncs;
  output list<DAE.Exp> outExpLst;
  output list<DAE.Exp> outExpLst1;
algorithm    
  (outExpLst,outExpLst1) := matchcontinue (inExp,inDExp,inExpLst,inExpLst1,inVarsandFuncs)
    local 
      BackendDAE.Variables timevars;
      DAE.FunctionTree functions;
      Absyn.Path a,da;
      Integer derivativeOrder;
      DAE.Type tp,dtp;
      list<DAE.Type> tlst,tlst1,tlst2;
      list<DAE.Exp> explst,dexplst,dexplst1,dexplst_1,dexplst1_1;
      list<Boolean> blst,blst1;
      list<String> typlststring;
      String typstring,dastring;      
    
    // order=1  
    case (DAE.CALL(path=a),DAE.CALL(path=da),inExpLst,inExpLst1,(timevars,functions))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=1),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        // remove all outputs not subtyp of real
        blst = Util.listMap(tlst,Types.isRealOrSubTypeReal);
        blst1 = listReverse(blst);      
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        (tlst1,_) = Util.listSplitOnBoolList(tlst,blst);
        true =  Util.isListEqualWithCompareFunc(tlst1,tlst2,Types.equivtypes); 
        // diff explst
        (dexplst,_) = Util.listSplitOnBoolList(inExpLst,blst);
        (dexplst1,_) = Util.listSplitOnBoolList(inExpLst1,blst1);
        dexplst_1 = Util.listMap1(dexplst,differentiateExpTime,(timevars,functions));        
        dexplst1_1 = Util.listMap1(dexplst1,differentiateExpTime,(timevars,functions));        
      then
        (dexplst_1,dexplst1_1);
    
    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,functions))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=1),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);
        // remove all outputs not subtyp of real
        blst = Util.listMap(tlst,Types.isRealOrSubTypeReal);
        blst1 = listReverse(blst);
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);    
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        (tlst1,_) = Util.listSplitOnBoolList(tlst,blst);
        false = Util.isListEqualWithCompareFunc(tlst1,tlst2,Types.equivtypes); 
        // add Warning
        typlststring = Util.listMap(tlst1,Types.unparseType);
        typstring = Util.stringDelimitList(typlststring,";");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXCPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});      
      then
        fail();        
    
    // order>1  
    case (DAE.CALL(path=a),DAE.CALL(path=da),inExpLst,inExpLst1,(timevars,functions))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=derivativeOrder),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);        
        true = (derivativeOrder > 1);       
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);    
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        true = Util.isListEqualWithCompareFunc(tlst,tlst2,Types.equivtypes); 
        // diff explst
        dexplst_1 = Util.listMap1(inExpLst,differentiateExpTime,(timevars,functions));        
        dexplst1_1 = Util.listMap1(inExpLst1,differentiateExpTime,(timevars,functions));        
      then
        (dexplst_1,dexplst1_1);
    
    case (DAE.CALL(path=a),DAE.CALL(path=da),_,_,(timevars,functions))
      equation
        // get function mapper
        (DAE.FUNCTION_DER_MAPPER(derivativeOrder=derivativeOrder),tp) = getFunctionMapper(a,functions);
        tlst = getFunctionResultTypes(tp);        
        true = (derivativeOrder > 1);       
        SOME(DAE.FUNCTION(type_=dtp)) = DAEUtil.avlTreeGet(functions,da);    
        // check if derivativ function has all expected outputs
        tlst2 = getFunctionResultTypes(dtp);
        false = Util.isListEqualWithCompareFunc(tlst,tlst2,Types.equivtypes);     
        // add Warning
        typlststring = Util.listMap(tlst,Types.unparseType);
        typstring = Util.stringDelimitList(typlststring,";");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXCPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});        
      then
        fail();        
  end matchcontinue;
end differentiateFunctionTimeOutputs;

protected function getFunctionResultTypes"
Author: Frenkel TUD"
  input DAE.Type inType;
  output list<DAE.Type> outTypLst;
algorithm
  outTypLst := matchcontinue (inType)
     local
       list<DAE.Type> tlst;
       DAE.Type t;
    case ((DAE.T_FUNCTION(funcResultType=(DAE.T_TUPLE(tupleType=tlst),_)),_)) then tlst;
    case ((DAE.T_FUNCTION(funcResultType=t),_)) then {t};
    case (inType) then {inType};
  end matchcontinue;    
end getFunctionResultTypes;

protected function differentiateFunctionTime"
Author: Frenkel TUD"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVarsandFuncs;
  output DAE.Exp outExp;  
algorithm    
  (outExp) := matchcontinue (inExp,inVarsandFuncs)
    local 
      list<DAE.Exp> expl,expl1,dexpl;
      DAE.Exp e,e1;
      BackendDAE.Variables timevars;
      Absyn.Path a,da;
      Boolean b,c;
      DAE.InlineType inl,dinl;
      DAE.ExpType ty;
      DAE.FunctionTree functions;
      DAE.FunctionDefinition mapper;
      DAE.Type tp,dtp;
      list<Boolean> blst;
      list<DAE.Type> tlst;
      list<String> typlststring;
      String typstring,dastring;
    
    case (DAE.CALL(path=a,expLst=expl,tuple_=b,builtin=c,ty=ty,inlineType=inl),(timevars,functions))
      equation
        // get function mapper
        (mapper,tp) = getFunctionMapper(a,functions);
        (da,blst) = differentiateFunctionTime1(a,mapper,tp,expl,(timevars,functions));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected inputs 
        (true,_) = checkDerivativeFunctionInputs(blst,tp,dtp);
        (expl1,_) = Util.listSplitOnBoolList(expl,blst);
        dexpl = Util.listMap1(expl1,differentiateExpTime,(timevars,functions));
        expl1 = listAppend(expl,dexpl);
      then
        DAE.CALL(da,expl1,b,c,ty,dinl);
    
    case (DAE.CALL(path=a,expLst=expl,tuple_=b,builtin=c,ty=ty,inlineType=inl),(timevars,functions))
      equation
        // get function mapper
        (mapper,tp) = getFunctionMapper(a,functions);
        (da,blst) = differentiateFunctionTime1(a,mapper,tp,expl,(timevars,functions));
        SOME(DAE.FUNCTION(type_=dtp,inlineType=dinl)) = DAEUtil.avlTreeGet(functions,da);
        // check if derivativ function has all expected inputs 
        (false,tlst) = checkDerivativeFunctionInputs(blst,tp,dtp);
        // add Warning
        typlststring = Util.listMap(tlst,Types.unparseType);
        typstring = Util.stringDelimitList(typlststring,";");
        dastring = Absyn.pathString(da);
        Error.addMessage(Error.UNEXCPECTED_FUNCTION_INPUTS_WARNING, {dastring,typstring});        
      then
        fail();        
  end matchcontinue;
end differentiateFunctionTime;

protected function checkDerivativeFunctionInputs"
Author: Frenkel TUD"
  input list<Boolean> blst;
  input DAE.Type tp;
  input DAE.Type dtp;
  output Boolean outBoolean;
  output list<DAE.Type> outExpectedTypeLst;
algorithm
  (outBoolean,outExpectedTypeLst) := matchcontinue(blst,tp,dtp)
    local
      list<DAE.FuncArg> falst,falst1,falst2,dfalst;
      list<DAE.Type> tlst,dtlst;
      Boolean ret;
      case (blst,(DAE.T_FUNCTION(funcArg=falst),_),(DAE.T_FUNCTION(funcArg=dfalst),_))
      equation
        // generate expected function inputs
        (falst1,_) = Util.listSplitOnBoolList(falst,blst);
        falst2 = listAppend(falst,falst1);
        // compare with derivative function inputs
        tlst = Util.listMap(falst2,Util.tuple22);
        dtlst = Util.listMap(dfalst,Util.tuple22);
        ret = Util.isListEqualWithCompareFunc(tlst,dtlst,Types.equivtypes);     
      then 
        (ret,tlst);
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "-Derive.checkDerivativeFunctionInputs failed\n");
      then
        fail();        
    end matchcontinue;
end checkDerivativeFunctionInputs;

protected function differentiateFunctionTime1"
Author: Frenkel TUD"
  input Absyn.Path inFuncName;
  input DAE.FunctionDefinition mapper;
  input DAE.Type tp;
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVarsandFuncs;
  output Absyn.Path outFuncName;
  output list<Boolean> blst;  
algorithm    
  (outFuncName,blst) := matchcontinue (inFuncName,mapper,tp,expl,inVarsandFuncs)
    local 
      BackendDAE.Variables timevars;
      DAE.FunctionTree functions;
      tuple<Integer,DAE.derivativeCond> cond;
      Absyn.Path default,fname,da,inDFuncName;
      DAE.TType typ;
      list<tuple<Integer,DAE.derivativeCond>> cr,cr1;
      Integer derivativeOrder;
      Option<Absyn.Path> dd; 
      Integer do;
      list<DAE.FuncArg> funcArg;
      list<DAE.Type> tplst; 
      list<Boolean> bl,bl1,bl2,bl3;
      list<Absyn.Path> lowerOrderDerivatives;
    // check conditions, order=1  
    case (inFuncName,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),(DAE.T_FUNCTION(funcArg=funcArg),_),expl,(timevars,functions))
      equation
         true = intEq(1,derivativeOrder);
         tplst = Util.listMap(funcArg,Util.tuple22);
         bl = Util.listMap(tplst,Types.isRealOrSubTypeReal);
         bl1 = checkDerFunctionConds(bl,cr,expl,(timevars,functions));
      then
        (inDFuncName,bl1);
    // check conditions, order>1  
    case (inFuncName,DAE.FUNCTION_DER_MAPPER(derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr),tp,expl,(timevars,functions))
      equation
         failure(true = intEq(1,derivativeOrder));
         // get n-1 func name
         fname = getlowerOrderDerivative(inFuncName,functions);
         // get mapper
         (mapper,tp) = getFunctionMapper(fname,functions);
         // get bool list
         (da,blst) = differentiateFunctionTime1(fname,mapper,tp,expl,(timevars,functions));
         // count true
         (bl1,_) = Util.listSplitOnTrue1(blst,Util.isEqual,true);
         bl2 = Util.listFill(false,listLength(blst));
         bl = listAppend(bl2,bl1);         
         bl3 = checkDerFunctionConds(bl,cr,expl,(timevars,functions));
      then
        (inDFuncName,bl3);        
    // conditions failed use default 
    case (inFuncName,DAE.FUNCTION_DER_MAPPER(derivedFunction=fname,derivativeFunction=inDFuncName,derivativeOrder=derivativeOrder,conditionRefs=cr,defaultDerivative=SOME(default),lowerOrderDerivatives=lowerOrderDerivatives),tp,expl,(timevars,functions))
      equation
          (da,bl) = differentiateFunctionTime1(inFuncName,DAE.FUNCTION_DER_MAPPER(fname,default,derivativeOrder,{},SOME(default),lowerOrderDerivatives),tp,expl,(timevars,functions));
      then
        (da,bl);    
  end matchcontinue;
end differentiateFunctionTime1;

protected function checkDerFunctionConds "
Author: Frenkel TUD"
  input list<Boolean> inblst;
  input list<tuple<Integer,DAE.derivativeCond>> crlst;
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> inVarsandFuncs;
  output list<Boolean> outblst;
algorithm
  outblst := matchcontinue(inblst,crlst,expl,inVarsandFuncs)
    local 
      Integer i,i_1;
      DAE.Exp e,de;
      list<Boolean> bl,bl1;
      array<Boolean> ba;
      Absyn.Path p1,p2;
    
    // no conditions
    case(inblst,{},expl,inVarsandFuncs) then inblst;
    
    // zeroDerivative
    case(inblst,(i,DAE.ZERO_DERIVATIVE())::crlst,expl,inVarsandFuncs)
      equation
        i_1 = i-1;
        // get expression
        e = listNth(expl,i_1);
        // diverentiate exp
        de = differentiateExpTime(e,inVarsandFuncs);
        // is diverentiated exp zero
        true = Expression.isZero(de);
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs); 
      then 
        bl;
    
    // noDerivative
    case(inblst,(i,DAE.NO_DERIVATIVE(binding=DAE.CALL(path=p1)))::crlst,expl,inVarsandFuncs)
      equation
        i_1 = i-1;
        // get expression
        DAE.CALL(path=p2) = listNth(expl,i_1);
        true = Absyn.pathEqual(p1, p2);
        // path equal
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);      
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs); 
      then 
        bl;
    
    // noDerivative  
    case(inblst,(i,DAE.NO_DERIVATIVE(binding=DAE.ICONST(_)))::crlst,expl,inVarsandFuncs)
      equation
        // remove input from list
        ba = listArray(inblst);
        ba = arrayUpdate(ba,i,false);
        bl1 = arrayList(ba);      
        bl = checkDerFunctionConds(bl1,crlst,expl,inVarsandFuncs); 
      then 
        bl;
    
    // failure
    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "-Derive.checkDerFunctionConds failed\n");
      then
        fail();       
  end matchcontinue;
end checkDerFunctionConds;

public function getlowerOrderDerivative"
Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output Absyn.Path outFName;
algorithm
  outFName := matchcontinue(fname,functions)
    local 
      list<DAE.FunctionDefinition> flst;
      list<Absyn.Path> lowerOrderDerivatives;
      Absyn.Path name;
    case(fname,functions)
      equation
          SOME(DAE.FUNCTION(functions=flst)) = DAEUtil.avlTreeGet(functions,fname);
          DAE.FUNCTION_DER_MAPPER(lowerOrderDerivatives=lowerOrderDerivatives) = getFunctionMapper1(flst);
          name = Util.listLast(lowerOrderDerivatives);
      then name;
  end matchcontinue;
end getlowerOrderDerivative;

public function getFunctionMapper"
Author: Frenkel TUD"
  input Absyn.Path fname;
  input DAE.FunctionTree functions;
  output DAE.FunctionDefinition mapper;
  output DAE.Type tp;
algorithm
  (mapper,tp) := matchcontinue(fname,functions)
    local 
      list<DAE.FunctionDefinition> flst;
      DAE.Type t;
      DAE.FunctionDefinition m;
      String s,s1,s2;
    case(fname,functions)
      equation
        SOME(DAE.FUNCTION(functions=flst,type_=t)) = DAEUtil.avlTreeGet(functions,fname);
        m = getFunctionMapper1(flst);
      then (m,t);
    case (fname,functions)
      equation
        s = Absyn.pathString(fname);
        s1 = stringAppend("-Derive.getFunctionMapper failed for function ",s);
        s2 = stringAppend(s1,"\n");
        Debug.fprintln("failtrace", s1 );
      then
        fail();
  end matchcontinue;
end getFunctionMapper;

public function getFunctionMapper1"
Author: Frenkel TUD"
  input list<DAE.FunctionDefinition> funcDefs;
  output DAE.FunctionDefinition mapper;
algorithm
  mapper := matchcontinue(funcDefs)
  local 
    DAE.FunctionDefinition m;
    Absyn.Path p1;
    case((m as DAE.FUNCTION_DER_MAPPER(derivativeFunction=p1))::funcDefs) then m;
    case(_::funcDefs)
    equation
      m = getFunctionMapper1(funcDefs);
    then m;
    case (_)
      equation
        Debug.fprintln("failtrace", "-Derive.getFunctionMapper1 failed\n");
      then
        fail();      
  end matchcontinue;
end getFunctionMapper1;

public function differentiateExpCont "calls differentiateExp(e,cr,false)"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp := differentiateExp(inExp,inComponentRef,false);
end differentiateExpCont;

public function differentiateExp "function: differentiateExp
  This function differentiates expressions with respect 
  to a given variable,given as second argument.
  For example: differentiateExp(2xy+2x+y,x) => 2x+2"
  input DAE.Exp inExp;
  input DAE.ComponentRef inComponentRef;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inComponentRef,differentiateIfExp)
    local
      Real rval;
      DAE.ComponentRef cr,crx,tv;
      DAE.Exp e,e1_1,e2_1,e1,e2,const_one,d_e1,d_e2,exp,e_1,exp_1,e3_1,e3,cond;
      DAE.ExpType tp, ctp;      
      Absyn.Path a,fname;
      Boolean b,c;
      DAE.InlineType inl;
      DAE.Operator op,rel;
      String e_str,s,s2,str;
      list<DAE.Exp> expl_1,expl,sub;
      Integer i;
		  list<Boolean> bLst;      
    
    case (DAE.ICONST(integer = _),_,_) then DAE.RCONST(0.0);

    case (DAE.RCONST(real = _),_,_) then DAE.RCONST(0.0);

    case (DAE.CREF(componentRef = cr),crx,_)
      equation
        true = ComponentReference.crefEqual(cr, crx) "D(x)/dx => 1" ;
        rval = intReal(1) "Since bug in MetaModelica Compiler (MMC) makes 1.0 into 0.0" ;
      then
        DAE.RCONST(rval);

    case ((e as DAE.CREF(componentRef = cr)),crx,_)
      equation
        false = ComponentReference.crefEqual(cr, crx) "D(c)/dx => 0" ;
      then
        DAE.RCONST(0.0);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.ADD(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.ADD_ARR(tp),e2_1);        

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.SUB(tp),e2_1);

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(e1_1,DAE.SUB_ARR(tp),e2_1);

    case (DAE.BINARY(exp1 = (e1 as DAE.CREF(componentRef = cr)),operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        true = ComponentReference.crefEqual(cr, tv) "x^a => ax^(a-1)" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(tv,tp));
        const_one = differentiateExp(Expression.makeCrefExp(tv,tp), tv, differentiateIfExp);
      then
        DAE.BINARY(e2,DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* ax^(a-1) */
      equation
        d_e1 = differentiateExp(e1, tv, differentiateIfExp) "e^x => xder(e)e^x-1" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(tv,tp));
        const_one = differentiateExp(Expression.makeCrefExp(tv,tp), tv, differentiateIfExp);
        exp = DAE.BINARY(
          DAE.BINARY(d_e1,DAE.MUL(tp),DAE.BINARY(e2,DAE.SUB(tp),DAE.RCONST(1.0))),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));
      then
        exp;

      case (e as DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp) /* a^x => a^x * log(A) */
      equation
        false = Expression.expContains(e1, Expression.makeCrefExp(tv,tp));
        true  = Expression.expContains(e2,Expression.makeCrefExp(tv,tp));
        d_e2 = differentiateExp(e2, tv, differentiateIfExp);
        exp = DAE.BINARY(d_e2,DAE.MUL(tp),
	        DAE.BINARY(e,DAE.MUL(tp),DAE.CALL(Absyn.IDENT("log"),{e1},false,true,tp,DAE.NO_INLINE()))
          );
      then
        exp;

    // ax^(a-1)
    case (DAE.BINARY(exp1 = (e1 as DAE.CALL(path = (a as Absyn.IDENT(name = "der")),
          expLst = {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=ctp,inlineType=inl)),
          operator = DAE.POW(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        true = ComponentReference.crefEqual(cr, tv) "der(e)^x => xder(e,2)der(e)^(x-1)" ;
        false = Expression.expContains(e2, Expression.makeCrefExp(tv,tp));
        const_one = differentiateExp(Expression.makeCrefExp(tv,tp), tv, differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,ctp,inl),DAE.MUL(tp),e2),DAE.MUL(tp),
          DAE.BINARY(e1,DAE.POW(tp),DAE.BINARY(e2,DAE.SUB(tp),const_one)));

    // f\'g + fg\'
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2_1),DAE.ADD(tp),
          DAE.BINARY(e1_1,DAE.MUL(tp),e2));

    // (f'g - fg' ) / g^2
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(
          	DAE.BINARY(e1_1,DAE.MUL(tp),e2),
          	DAE.SUB(tp),
          	DAE.BINARY(e1,DAE.MUL(tp),e2_1)),
          DAE.DIV(tp),
          DAE.BINARY(e2,DAE.MUL(tp),e2));
    
    case (DAE.UNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv, differentiateIfExp);
      then
        DAE.UNARY(op,e_1);
    
    // abs(x)
    case (DAE.CALL(path=fname, expLst={exp},tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp) 
      equation
        Builtin.isAbs(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then 
        DAE.IFEXP(DAE.RELATION(exp_1,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(0.0)), exp_1, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),exp_1));
    
    // der(tanh(x)) = der(x) / cosh(x)
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isTanh(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp,inl));

    // der(cosh(x)) => der(x)sinh(x)
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isCosh(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sinh"),{exp},b,c,tp,inl));

    // der(sinh(x)) => der(x)sinh(x)
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isSinh(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("cosh"),{exp},b,c,tp,inl));

    // sin(x)
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isSin(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp,inl),DAE.MUL(DAE.ET_REAL()),exp_1);

    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isCos(fname);
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(
          DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{exp},b,c,tp,inl)),DAE.MUL(DAE.ET_REAL()),exp_1);

    // der(arccos(x)) = -der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        Builtin.isACos(fname);
        true = Expression.expContains(e, Expression.crefExp(tv));
        e_1 = differentiateExp(e, tv, differentiateIfExp)  ;
      then
        DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE())));
    
    // der(arcsin(x)) = der(x)/sqrt(1-x^2)
    case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        Builtin.isASin(fname);
        true = Expression.expContains(e, Expression.crefExp(tv));
        e_1 = differentiateExp(e, tv, differentiateIfExp)  ;
      then
       DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{DAE.BINARY(DAE.RCONST(1.0),DAE.SUB(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e))},
                   false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
    
    // der(arctan(x)) = der(x)/1+x^2
    case (DAE.CALL(path = fname,expLst = {e}),tv,differentiateIfExp)
      equation
        Builtin.isATan(fname);
        true = Expression.expContains(e, Expression.crefExp(tv));
        e_1 = differentiateExp(e, tv, differentiateIfExp)  ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));
    
    // der(arctan2(y,0)) = der(sign(y)*pi/2) = 0
    case (DAE.CALL(path = fname,expLst = {e,e1}),tv,differentiateIfExp)
      equation
        Builtin.isATan2(fname);
        true = Expression.expContains(e, Expression.crefExp(tv));
        true = Expression.isZero(e1);
        (exp,_) = Expression.makeZeroExpression({});
      then
       exp;

    // der(arctan2(y,x)) = der(y/x)/1+(y/x)^2
    case (DAE.CALL(path = fname,expLst = {e,e1}),tv,differentiateIfExp)
      equation
        Builtin.isATan2(fname);
        true = Expression.expContains(e, Expression.crefExp(tv));
        false = Expression.isZero(e1);
        exp = Expression.makeDiv(e,e1);
        e_1 = differentiateExp(exp, tv, differentiateIfExp)  ;
      then
        DAE.BINARY(e_1,DAE.DIV(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(1.0),DAE.ADD(DAE.ET_REAL()),DAE.BINARY(e,DAE.MUL(DAE.ET_REAL()),e)));
           
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isExp(fname) "exp(x) => x\'  exp(x)" ;
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(fname,(exp :: {}),b,c,tp,inl),DAE.MUL(DAE.ET_REAL()),exp_1);
    
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        Builtin.isLog(fname) "log(x) => x\'  1/x" ;
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),exp));
    
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isLog10(fname) "log10(x) => x\'1/(xlog(10))" ;
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(exp_1,DAE.MUL(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(exp,DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},b,c,tp,inl))));
    
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),(exp :: {}),b,c,tp,inl))),DAE.MUL(DAE.ET_REAL()),exp_1);
    
    case (DAE.CALL(path = fname,expLst = (exp :: {}),tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        Builtin.isTan(fname) "tan x => 1/((cos x)^2)" ;
        true = Expression.expContains(exp, Expression.crefExp(tv));
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.CALL(Absyn.IDENT("cos"),{exp},b,c,tp,inl),DAE.POW(DAE.ET_REAL()),
          DAE.RCONST(2.0))),DAE.MUL(DAE.ET_REAL()),exp_1);
    
    case (DAE.CALL(path = Absyn.IDENT("der"), expLst = {DAE.CREF(componentRef = cr)}), crx, differentiateIfExp)
      equation
        cr = ComponentReference.makeCrefQual("$DER", DAE.ET_REAL(), {}, cr);
        true = ComponentReference.crefEqual(cr, crx);
        rval = intReal(1);
      then
        DAE.RCONST(rval);
        
    // derivative of arbitrary function, not dependent of variable, i.e. constant
		case (DAE.CALL(fname,expl,b,c,tp,inl),tv,differentiateIfExp)
      equation
        bLst = Util.listMap1(expl,Expression.expContains, Expression.crefExp(tv));
        false = Util.listReduce(bLst,boolOr);
        (e1,_) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then
        e1;
    
    case ((e as DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2)),tv,differentiateIfExp)
      equation
        e_str = ExpressionDump.printExpStr(e) "The derivative of logic expressions are non-existent" ;
        Error.addMessage(Error.NON_EXISTING_DERIVATIVE, {e_str});
      then
        fail();
    
    case (DAE.LUNARY(operator = op,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv, differentiateIfExp);
      then
        DAE.LUNARY(op,e_1);
    
    case (DAE.RELATION(exp1 = e1,operator = rel,exp2 = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.RELATION(e1_1,rel,e2_1);

    // der(x)
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "der")),expLst =
          {(exp as DAE.CREF(componentRef = cr))},tuple_ = b,builtin = c,ty=tp,inlineType=inl),tv,differentiateIfExp)
      equation
        true = ComponentReference.crefEqual(cr, tv);
      then
        DAE.CALL(a,{exp,DAE.ICONST(2)},b,c,tp,inl);
    
    // der(abs(x)) = sign(x)der(x)
    case (DAE.CALL(path = (a as Absyn.IDENT(name = "abs")),expLst = {exp},tuple_ = b,builtin = c),tv,differentiateIfExp)
      equation
        exp_1 = differentiateExp(exp, tv, differentiateIfExp);
      then
        DAE.BINARY(DAE.CALL(Absyn.IDENT("sign"),{exp_1},false,true,DAE.ET_INT(),DAE.NO_INLINE()),
          DAE.MUL(DAE.ET_REAL()),exp_1);
    
    case (DAE.ARRAY(ty = tp,scalar = b,array = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv, differentiateIfExp);
      then
        DAE.ARRAY(tp,b,expl_1);
    
    case (DAE.TUPLE(PR = expl),tv,differentiateIfExp)
      equation
        expl_1 = Util.listMap2(expl, differentiateExp, tv, differentiateIfExp);
      then
        DAE.TUPLE(expl_1);
    
    case (DAE.CAST(ty = tp,exp = e),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv, differentiateIfExp);
      then
        DAE.CAST(tp,e_1);
    
    case (DAE.ASUB(exp = e,sub = sub),tv,differentiateIfExp)
      equation
        e_1 = differentiateExp(e, tv, differentiateIfExp);
      then
        Expression.makeASUB(e_1,sub);
    
    case (DAE.REDUCTION(path = a,expr = e1,ident = str,range = e2),tv,differentiateIfExp)
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then
        DAE.REDUCTION(a,e1_1,str,e2_1);
    
    case (e,cr,differentiateIfExp)
      equation
        false = Expression.expContains(e, Expression.crefExp(cr)) 
        "If the expression does not contain the variable,
	       the derivative is zero. For efficiency reasons this rule
	       is last. Otherwise expressions is allways traversed twice
	       when differentiating." ;
      then
        DAE.RCONST(0.0);

    // Differentiate if-expressions if last argument true
    case (DAE.IFEXP(cond,e1,e2),tv,differentiateIfExp as true) 
      equation
        e1_1 = differentiateExp(e1, tv, differentiateIfExp);
        e2_1 = differentiateExp(e2, tv, differentiateIfExp);
      then 
        DAE.IFEXP(cond,e1_1,e2_1);
    
    case (e,cr,differentiateIfExp)
      equation
				true = RTOpts.debugFlag("failtrace");
        s = ExpressionDump.printExpStr(e);
        s2 = ComponentReference.printComponentRefStr(cr);
        str = stringAppendList({"- Derive.differentiateExp ",s," w.r.t: ",s2," failed\n"});
        //print(str);
        Debug.fprint("failtrace", str);
      then
        fail();
  end matchcontinue;
end differentiateExp;

end Derive;

