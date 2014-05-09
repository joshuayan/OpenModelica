#pragma once





/*****************************************************************************
*
* Simulation code for Modelica generated by the OpenModelica Compiler.
* System class Modelica implements the Interface IMixedSystem
*
*****************************************************************************/



class Modelica: public IMixedSystem ,public IContinuous ,public IEvent ,public ISystemProperties, public SystemDefaultImplementation
 {
      public:

      Modelica(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData>);

  ~Modelica();

  //Releases the Modelica System
   virtual void destroy();

   // Geerbt von IContinuous
   //////////////////////////////////////////////////
   virtual int getDimBoolean() const;

   /// Provide number (dimension) of states
   virtual int getDimContinuousStates() const;

      /// Provide number (dimension) of integer variables
      virtual int getDimInteger() const;

      /// Provide number (dimension) of real variables
      virtual int getDimReal() const;

      /// Provide number (dimension) of string variables
      virtual int getDimString() const;

      /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
      virtual int getDimRHS() const;


      /// Provide boolean variables
      virtual void getBoolean(bool* z);

      /// Provide boolean variables
      virtual void getContinuousStates(double* z);

      /// Provide integer variables
      virtual void getInteger(int* z);

      /// Provide real variables
      virtual void getReal(double* z);

      /// Provide real variables
      virtual void getString(std::string* z);

      /// Provide the right hand side
      virtual void getRHS(double* f);


      /// Provide boolean variables
      virtual void setBoolean(const bool* z);

      /// Provide boolean variables
      virtual void setContinuousStates(const double* z);

      /// Provide integer variables
      virtual void setInteger(const int* z);

      /// Provide real variables
      virtual void setReal(const double* z);

      /// Provide real variables
      virtual void setString(const std::string* z);

      /// Provide the right hand side
      virtual void setRHS(const double* f);

      // Update transfer behavior of the system of equations according to command given by solver
   virtual bool evaluate(const UPDATETYPE command = IContinuous::UNDEF_UPDATE);




  //Resets all time events
   virtual void resetTimeEvents();

  //Set current integration time
   virtual void setTime(const double& t);






  // Provide Jacobian
   virtual void getJacobian(SparseMatrix& matrix);
   virtual void getStateSetJacobian(SparseMatrix& matrix);
  // Provide number (dimension) of zero functions
   virtual int getDimZeroFunc() ;

  // Provides current values of root/zero functions
   virtual void getZeroFunc(double* f);
   virtual bool checkConditions();
   virtual void getConditions(bool* c);

   //Called to handle all  events occured at same time
   virtual bool handleSystemEvents( bool* events);
  //Called to handle an event
   virtual void handleEvent(const bool* events);

  //Checks if a discrete variable has changed and triggers an event
   virtual bool checkForDiscreteEvents();



  // M is regular
   virtual bool isODE();

  // M is singular
   virtual bool isAlgebraic();

  // System is able to provide the Jacobian symbolically
   virtual bool provideSymbolicJacobian() ;
   virtual void saveDiscreteVars();
   virtual void stepCompleted(double time);
private:

  //Methods:
  //Saves all variables before an event is handled, is needed for the pre, edge and change operator
  void saveAll();

   void resetHelpVar(const int index);

};
