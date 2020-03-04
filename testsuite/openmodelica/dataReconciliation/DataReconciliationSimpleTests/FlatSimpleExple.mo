within DataReconciliationSimpleTests;
model FlatSimpleExple
  Real q1(uncertain=Uncertainty.refine)=1;
  Real q2(uncertain=Uncertainty.refine)=2;
  Real q3(uncertain=Uncertainty.refine);
  Real q4(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
equation
  q1=q2 + q3;
  q4=q2 + q3;
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                                    "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                                    "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                                    "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                                    "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
            fillPattern =                                                                                                   FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                     "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
            fillPattern =                                                                                                   FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                     "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
            fillPattern =                                                                                                   FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                     "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
            fillPattern =                                                                                                   FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
            =                                                                                     "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}));
end FlatSimpleExple;
