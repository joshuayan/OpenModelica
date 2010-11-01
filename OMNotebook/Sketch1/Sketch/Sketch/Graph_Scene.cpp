#include "Graph_Scene.h"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
Graph_Scene::Graph_Scene(QObject* parent):QGraphicsScene(parent)
{
    object1 = new Scene_Objects;
    object2 = new Scene_Objects;
    object3 = new Scene_Objects;
    object5 = new Scene_Objects;
    copy_object1 = new Scene_Objects;

    copy_object1=NULL;

    arcs.clear();
    lines.clear();
    draw_object_state=0;
    lines.clear();
    rects.clear();
    round_rects.clear();
    elleps.clear();

    polygons.clear();

    objects.clear();
    pnts.clear();
    mode=false;

    polygon=new Draw_polygon();
    polygon->set_draw_mode(false);

    temp_polygon=new Draw_polygon();
    temp_polygon->set_draw_mode(false);

 }

void Graph_Scene::mousePressEvent(QGraphicsSceneMouseEvent *event)
{

    QPainter paint;
    bool k=false;

    if(event->button()==Qt::LeftButton)
    {
        //Mouse position is stored in strt_pnt and strt1_pnt;
        strt_pnt=event->scenePos();
        qDebug()<<"Screen pos "<<event->screenPos()<<"\n";
        //Function to select the object to be drawn
        draw_objects();
    }

    if(event->button()==Qt::RightButton)
    {
        //Mouse position is stored in strt_pnt and strt1_pnt;
        strt1_pnt=event->scenePos();
        qDebug()<<"right button pressed "<<strt1_pnt<<"\n";
    }

}

void Graph_Scene::mouseMoveEvent(QGraphicsSceneMouseEvent *event)
{
    if(draw_object_state==1)
         draw_line_move(event->lastScenePos(),event->scenePos());
    if(draw_object_state==2)
         draw_rect_move(event->lastScenePos(),event->scenePos());
    if(draw_object_state==3)
         draw_ellep_move(event->lastScenePos(),event->scenePos());
    if(draw_object_state==4)
         draw_polygon_move(event->lastScenePos(),event->scenePos());
    if(draw_object_state==5)
         draw_round_rect_move(event->lastScenePos(),event->scenePos());
    if(draw_object_state==6)
         draw_arc_move(event->lastScenePos(),event->scenePos());
}

void Graph_Scene::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
     QPen pen = QPen();
     if((event->button()==Qt::LeftButton))
     {
         if(draw_object_state==1)
         {
             draw_line_state(event->lastScenePos(),event->scenePos());
         }
         
         if(draw_object_state==2)
         {
             draw_rect_state(event->lastScenePos(),event->scenePos());
         }

         if(draw_object_state==3)
         {
             draw_ellep_state(event->lastScenePos(),event->scenePos());
         }

         if(draw_object_state==4)
         {
             draw_polygon_state(event->lastScenePos(),event->scenePos());
         }

         if(draw_object_state==5)
         {
             draw_round_rect_state(event->lastScenePos(),event->scenePos());
         }

         if(draw_object_state==6)
         {
             draw_arc_state(event->lastScenePos(),event->scenePos());
         }

     }
}

void Graph_Scene::mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event)
{

    if((event->button()==Qt::LeftButton))
    {
        if((draw_object_state==4)&&(polygon->get_draw_mode()==false))
        {
            Draw_polygon *polygon1 = new Draw_polygon();
            polygon1->polygonSetStrtPnt(pnts[0]);
            polygon1->polygonSetEndPnt(pnts[pnts.size()-1]);
            for(int i=0;i<pnts.size();i++)
            {
                polygon1->insert_pnt(pnts[i]);
            }
            polygon1->create_bound_edges();
            polygon1->set_draw_mode(true);
            polygons.push_back(polygon1);
            int i=polygons.size()-1;
            addLine(polygons[i]->polygon_strt_pnt.x(),polygons[i]->polygon_strt_pnt.y(),event->scenePos().x(),event->scenePos().y());
            mode=false;
            pnts.clear();

        }
    }
}

//KeyBoard event

void Graph_Scene::keyPressEvent(QKeyEvent *event)
{
    QPen pen = QPen();

    pen.setColor(QColor(255,255,255));
    if(event->key()==0x01000007)
    {
       if((draw_object_state==1)&&(line->getMode()))
       {
           addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
           removeItem(object1->item);
           objects.remove(object_indx);
           lines.remove(indx);
       }

       if((draw_object_state==2)&&(rect->getMode()))
       {
           addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
           removeItem(object2->item);
           objects.remove(object_indx);
           rects.remove(indx);
       }

       if((draw_object_state==3)&&(ellep->getMode()))
       {
           addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
           removeItem(object3->item);
           objects.remove(object_indx);
           elleps.remove(indx);
       }

    }


    if((event->key()==Qt::Key_C)) //controlled key
    {
        if((draw_object_state!=0)&&((draw_object_state==2)))
        {
            qDebug()<<"Rectangle is selected for copy \n";
        }
    }


}

bool Graph_Scene::check_object(QPointF pnt,Draw_Line* line1)
{
    int k=0;
    if(line1->getMode())
    {
       line1->get_strt_edge(pnt);
       line1->get_end_edge(pnt);
       line1->get_line(pnt);
       k=line1->getState();
       if((k==1)||(k==2)||(k==3))
       {
           qDebug()<<"value of k "<<k;
           return true;
       }
    }
}

void Graph_Scene::draw_object(QPointF pnt, QPointF pnt1, Draw_Line *line1,QPen pen)
{
     this->addLine(pnt.x(),pnt.y(),pnt1.x(),pnt1.y(),pen);
}

void Graph_Scene::draw_objects()
{
    int k=0,position;
    qDebug()<<"Objects size \t"<<objects.size()<<"\n";
    for(int i=0;i<objects.size();i++)
    {
        objects[i]->CheckPnt(strt_pnt);
        k=objects[i]->getObject(position);
        qDebug()<<"value ok k "<<k;
        if(k==1)
        {
            object1=objects[i];
            object_indx=i;

            //draw_object_state=1;
            break;
        }
        if(k==2)
        {
           object2=objects[i];
           object_indx=i;

           //draw_object_state=2;
           break;
        }

        if(k==3)
        {
           object3=objects[i];
           object_indx=i;

           //draw_object_state=3;
           break;
        }

        if(k==5)
        {
           object5=objects[i];
           object_indx=i;

           //draw_object_state=3;
           break;
        }

        /*if(k==6)
        {
           object6=objects[i];
           object_indx=i;

           //draw_object_state=3;
           break;
        }*/
   }

    if(k!=1 || k!=2 || k!=3|| k!=5)
        draw_object_state=prev_draw_object_state;
    if(k==1)
    {
        qDebug()<<"entered k value "<<k;
        draw_object_state=1;
    }

    if(k==2)
    {
        qDebug()<<"entered1 k value "<<k;
        draw_object_state=2;
    }

    if(k==3)
    {
        qDebug()<<"entered1 k value "<<k;
        draw_object_state=3;
    }

    if(k==5)
    {
        qDebug()<<"entered1 k value "<<k;
        draw_object_state=5;
    }

    if(k==6)
    {
        qDebug()<<"entered1 k value "<<k;
        draw_object_state=6;
    }


    if(draw_object_state==1)
    {
        draw_line();
    }

    if(draw_object_state==2)
    {
        draw_rect();
    }

    if(draw_object_state==3)
    {
        draw_ellep();
    }

    if(draw_object_state==4)
    {
        draw_polygon();
    }

    if(draw_object_state==5)
    {
        draw_round_rect();
    }

    if(draw_object_state==6)
    {
        draw_arc();
    }
}


void Graph_Scene::draw_arc()
{
    bool k=false;
    QPainterPath path = QPainterPath();
    QPainterPath path1 = QPainterPath();
    QPen pen = QPen();

    if(arcs.size()==0)
    {
        Draw_Arc* arc2 = new Draw_Arc();
        arc2->arc_strt_pnt=strt_pnt;
        arc=arc2;
        temp_arc=arc2;
        arcs.push_back(arc2);

    }

    //hide_object_edges();
   /* for(int i=0;i<arcs.size();i++)
    {

        if((check_object(strt_pnt,arcs[i]))&&(arcs[i]->getMode()==true))
        {
             pen.setColor(QColor(0,0,0));
             path.addRect(arcs[i]->getArcstartPnt().x(),arcs[i]->getArcstartPnt().y(),5.0,5.0);
             path.addRect(arcs[i]->getArcendPnt().x(),arcs[i]->getArcendPnt().y(),5.0,5.0);
             addPath(path,pen);
             arc=arcs[i];
             k=true;
             break;
        }
    }
    if(k==true)
    {
        //qDebug()<<"enetred\n";
       qDebug()<<arc->getState();
    }
    else if(arc->getMode()==true)
    {
        hide_edges();
        Draw_RoundRect* arc2 = new Draw_RoundRect();
        arc=arc2;
        arcs.push_back(arc2);
        arc2->arc_strt_pnt=strt_pnt;
        //qDebug()<<"enetered and created a new rect\n";
    }*/
}

bool Graph_Scene::check_object(QPointF pnt,Draw_Arc* arc1)
{
    int k=0;
    if(arc1->getMode())
    {
       arc1->get_strt_edge(pnt);
       arc1->get_end_edge(pnt);
       arc1->get_line(pnt);
       k=arc1->getState();
       if((k==1)||(k==2)||(k==3))
       {
           //qDebug()<<"value of k "<<k;
           return true;
       }
    }
}


void Graph_Scene::draw_arc_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    QPixmap map = QPixmap();
    QPainter paint_arc;

    //QPainterPath paint_arc = QPainterPath();
    //QPainterPath paint_arc1 = QPainterPath();

     for(int i=0;i<arcs.size();i++)
     {
        if((pnt1!=pnt)&&(arcs[i]->getMode()==false))
        {
            //pen.setColor(QColor(255,255,255));
            pen.setColor(QColor(0,0,0));
            paint_arc.begin(&map);
            paint_arc.drawArc(arcs[i]->arc_strt_pnt.x(),arcs[i]->arc_strt_pnt.y(),pnt.x()-arcs[i]->arc_strt_pnt.x(),pnt.y()-arcs[i]->arc_strt_pnt.y(),10,60);
            paint_arc.end();
            addPixmap(map);
            //pen.setColor(QColor(0,0,0));
            //paint_arc1.arcTo(arcs[i]->arc_strt_pnt.x(),arcs[i]->arc_strt_pnt.y(),pnt1.x()-arcs[i]->arc_strt_pnt.x(),pnt1.y()-arcs[i]->arc_strt_pnt.y(),1,1);
            //addPath(paint_arc1,pen);
        }
     }

     /*if(round_rect->getMode())
     {
         if(round_rect->getState()==1)
         {
              pen.setColor(QColor(255,255,255));
              paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
              paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
              paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
              addPath(paint_round_rect,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   paint_round_rect.addRoundedRect(pnt.x(),pnt.y(),round_rect->pnt.x()-pnt.x(),round_rect->pnt.y()-pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect.addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0);
                   paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                   addPath(paint_round_rect,pen);

                   pen.setColor(QColor(0,0,0));
                   paint_round_rect1.addRoundedRect(pnt1.x(),pnt1.y(),round_rect->pnt.x()-pnt1.x(),round_rect->pnt.y()-pnt1.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect1.addRect(pnt1.x()-5.0,pnt1.y()-2.5,5.0,5.0);
                   paint_round_rect1.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                   addPath(paint_round_rect1,pen);
                   round_rect->round_rect_strt_pnt=pnt1;
                   round_rect->bounding_strt_pnt=pnt1;
                   round_rect->bounding_end_pnt=round_rect->round_rect_end_pnt;
                   addPath(paint_round_rect1,pen);
               }
          }

          if(round_rect->getState()==2)
          {
              pen.setColor(QColor(255,255,255));
              paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
              paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
              paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
              addPath(paint_round_rect,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   paint_round_rect.addRoundedRect(round_rect->pnt.x(),round_rect->pnt.y(),pnt.x()-round_rect->pnt.x(),pnt.y()-round_rect->pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                   paint_round_rect.addRect(pnt.x(),pnt.y()-2.5,5.0,5.0);
                   addPath(paint_round_rect,pen);

                   pen.setColor(QColor(0,0,0));
                   paint_round_rect1.addRoundedRect(round_rect->pnt.x(),round_rect->pnt.y(),pnt1.x()-round_rect->pnt.x(),pnt1.y()-round_rect->pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect1.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                   paint_round_rect1.addRect(pnt1.x(),pnt1.y()-2.5,5.0,5.0);
                   round_rect->round_rect_end_pnt=pnt1;
                   round_rect->bounding_strt_pnt=round_rect->round_rect_strt_pnt;
                   round_rect->bounding_end_pnt=pnt1;
                   addPath(paint_round_rect1,pen);

               }
           }

           if(round_rect->getState()==3)
           {
               if(pnt1!=pnt)
               {
                    pen.setColor(QColor(255,255,255));
                    paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                    paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                    paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                    addPath(paint_round_rect,pen);
                    round_rect->translate(pnt,pnt1);

                    pen.setColor(QColor(0,0,0));
                    paint_round_rect1.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                    paint_round_rect1.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                    paint_round_rect1.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                    round_rect->bounding_strt_pnt=round_rect->round_rect_strt_pnt;
                    round_rect->bounding_end_pnt=round_rect->round_rect_end_pnt;
                    addPath(paint_round_rect1,pen);
                    draw_Scene();
                }
            }
        }*/
}

void Graph_Scene::draw_arc_state(QPointF pnt,QPointF pnt1)
{
    QPainterPath paint_arc = QPainterPath();
    QPen pen = QPen();
    Scene_Objects* object = new Scene_Objects();

    if(arc->getMode()==false)
    {
        last_pnt=pnt1;
        arc->setMode(true);
        arc->setArcEndPnt(pnt1);
        arc->bounding_strt_pnt = arc->arc_strt_pnt;
        arc->bounding_end_pnt = arc->arc_end_pnt;
        object->setObjectPos(arc->arc_strt_pnt,arc->arc_end_pnt);
        object->setObjects(6,arcs.size()-1);
        objects.push_back(object);

        /*pen.setColor(QColor(0,0,0));
        paint_arc.addRoundedRect(arc->arc_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
        paint_arc.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
        paint_arc.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
        addPath(paint_arc,pen);*/
    }

    /*if(round_rect->getMode()==true)
    {
        //qDebug()<<"Entered Point "<<rect->getState()<<"\n";

        if(round_rect->getState()==1)
        {
           object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
           round_rect->setState(0);
        }

        if(round_rect->getState()==2)
        {
            object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
            round_rect->setState(0);
        }

        if(round_rect->getState()==3)
        {
            object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
            round_rect->setState(0);
        }

     }*/
}


void Graph_Scene::draw_line()
{
    bool k=false;
    if(lines.size()==0)
    {
        Draw_Line* line2 = new Draw_Line();
        line2->line_strt_pnt=strt_pnt;
        line=line2;
        lines.push_back(line2);
    }
    hide_object_edges();
    for(int i=0;i<lines.size();i++)
    {
        if((check_object(strt_pnt,lines[i]))&&(lines[i]->getMode()==true))
        {
             line=lines[i];
             indx=i;
             k=true;
             break;
        }
    }
    if(k==true)
    {
        qDebug()<<line->getState();
    }
    else if(line->getMode()==true)
    {
        Draw_Line* line2 = new Draw_Line();
        line=line2;
        lines.push_back(line2);
        line2->line_strt_pnt=strt_pnt;
    }
}

void Graph_Scene::draw_line_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    for(int i=0;i<lines.size();i++)
     {
        if((pnt1!=pnt)&&(lines[i]->getMode()==false))
        {
            pen.setColor(QColor(255,255,255));
            draw_object(lines[i]->line_strt_pnt,pnt,lines[i],pen);
            pen.setColor(QColor(0,0,0));
            draw_object(lines[i]->line_strt_pnt,pnt1,lines[i],pen);
        }
     }

     if(line->getMode())
     {
         if(line->getState()==1)
         {
              pen.setColor(QColor(255,255,255));
              this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
              this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
              this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);

              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addLine(pnt.x(),pnt.y(),line->pnt.x(),line->pnt.y(),pen);
                   this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
                   this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);


                   pen.setColor(QColor(0,0,0));
                   this->addLine(pnt1.x(),pnt1.y(),line->pnt.x(),line->pnt.y(),pen);
                   this->addRect(pnt1.x()-5.0,pnt1.y()-2.5,5.0,5.0,pen);
                   this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
                   line->line_strt_pnt=pnt1;
                   line->bounding_strt_pnt=pnt1;
                   line->bounding_end_pnt=line->line_end_pnt;
               }
          }

          if(line->getState()==2)
          {
              pen.setColor(QColor(255,255,255));
              this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
              this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
              this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addLine(line->pnt.x(),line->pnt.y(),pnt.x(),pnt.y(),pen);
                   this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);

                   pen.setColor(QColor(0,0,0));
                   this->addLine(line->pnt.x(),line->pnt.y(),pnt1.x(),pnt1.y(),pen);
                   this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt1.x(),pnt1.y()-2.5,5.0,5.0,pen);
                   line->line_end_pnt=pnt1;
                   line->bounding_strt_pnt=line->line_strt_pnt;
                   line->bounding_end_pnt=pnt1;

               }
           }

           if(line->getState()==3)
           {
               if(pnt1!=pnt)
               {
                    pen.setColor(QColor(255,255,255));
                    this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
                    this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
                    this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
                    line->translate(pnt,pnt1);

                    pen.setColor(QColor(0,0,0));
                    this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
                    this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
                    this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
                    line->bounding_strt_pnt=line->line_strt_pnt;
                    line->bounding_end_pnt=line->line_end_pnt;
                    object1->setObjectPos(line->line_strt_pnt,line->line_end_pnt);
                    draw_Scene();
                }
            }
        }


}

void Graph_Scene::draw_line_state(QPointF pnt, QPointF pnt1)
{
    QPen pen = QPen();
    Scene_Objects* object = new Scene_Objects();
    if(line->getMode()==false)
    {
        last_pnt=pnt1;
        object->item = addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),pnt1.x(),pnt1.y());
        line->setMode(true);
        //lines[i]->setLineStartPnt(strt_pnt);
        line->setLineEndPnt(pnt1);
        line->bounding_strt_pnt = line->line_strt_pnt;
        line->bounding_end_pnt = line->line_end_pnt;
        //addItem(item);
        //update(line->line_strt_pnt.x(),line->line_strt_pnt.y(),pnt1.x(),pnt1.y());
        //setFocusItem(item);
        this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
        this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
        object->setObjectPos(line->line_strt_pnt,line->line_end_pnt);
        object->setObjects(1,lines.size()-1);
        objects.push_back(object);
    }

    if(line->getMode()==true)
    {
        qDebug()<<"Entered Point "<<line->getState()<<"\n";

        if(line->getState()==1)
        {
           //qDebug()<<"Entered Point\n";
           pen.setColor(QColor(255,255,255));
           //this->addLine(pnt1.x(),pnt1.y(),line->pnt.x(),line->pnt.y());
           /*this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
           this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);*/
           object1->setObjectPos(line->line_strt_pnt,line->line_end_pnt);
           line->setState(0);
        }

        if(line->getState()==2)
        {
            pen.setColor(QColor(255,255,255));
            //this->addLine(line->pnt.x(),line->pnt.y(),pnt1.x(),pnt1.y());
            /*this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
            this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);*/
            object1->setObjectPos(line->line_strt_pnt,line->line_end_pnt);
            line->setState(0);
        }

        if(line->getState()==3)
        {
            pen.setColor(QColor(255,255,255));
            //this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y());
            /*this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
            this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);*/
            object1->setObjectPos(line->line_strt_pnt,line->line_end_pnt);
            line->setState(0);

        }

     }
}

void Graph_Scene::draw_rect()
{
    bool k=false;


    if(rects.size()==0)
    {
        Draw_rect* rect2 = new Draw_rect();
        rect2->rect_strt_pnt=strt_pnt;
        rect=rect2;
        rects.push_back(rect2);
        //qDebug()<<"enetered and a new rect\n";
    }

     hide_object_edges();

    for(int i=0;i<rects.size();i++)
    {
        if((check_object(strt_pnt,rects[i]))&&(rects[i]->getMode()==true))
        {
             rect=rects[i];
             k=true;
             break;
        }
    }
    if(k==true)
    {
        //qDebug()<<"enetred\n";
        qDebug()<<rect->getState();
    }
    else if(rect->getMode()==true)
    {
        Draw_rect* rect2 = new Draw_rect();
        rect=rect2;
        rects.push_back(rect2);
        rect2->rect_strt_pnt=strt_pnt;
        //qDebug()<<"enetered and created a new rect\n";
    }
}

bool Graph_Scene::check_object(QPointF pnt,Draw_rect* rect1)
{
    int k=0;
    if(rect1->getMode())
    {
       rect1->get_strt_edge(pnt);
       rect1->get_end_edge(pnt);
       rect1->get_line(pnt);
       k=rect1->getState();
       if((k==1)||(k==2)||(k==3))
       {
           //qDebug()<<"value of k "<<k;
           return true;
       }
    }
}


void Graph_Scene::draw_rect_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    QPointF temp_pnt,temp_pnt1,temp_pnt2;

     for(int i=0;i<rects.size();i++)
     {
        if((pnt1!=pnt)&&(rects[i]->getMode()==false))
        {
            pen.setColor(QColor(255,255,255));
            if((rects[i]->rect_strt_pnt.x()>pnt.x())&&(rects[i]->rect_strt_pnt.y()<pnt.y()))
               addRect(pnt.x(),rects[i]->rect_strt_pnt.y(),rects[i]->rect_strt_pnt.x()-pnt.x(),pnt.y()-rects[i]->rect_strt_pnt.y(),pen);
            else if((rects[i]->rect_strt_pnt.y()>pnt.y())&&(rects[i]->rect_strt_pnt.x()<pnt.x()))
               addRect(rects[i]->rect_strt_pnt.x(),pnt.y(),pnt.x()-rects[i]->rect_strt_pnt.x(),rects[i]->rect_strt_pnt.y()-pnt.y(),pen);
            else if((rects[i]->rect_strt_pnt.x()>pnt.x()) && (rects[i]->rect_strt_pnt.y()>pnt.y()))
               addRect(pnt.x(),pnt.y(),rects[i]->rect_strt_pnt.x()-pnt.x(),rects[i]->rect_strt_pnt.y()-pnt.y(),pen);
            else
               addRect(rects[i]->rect_strt_pnt.x(),rects[i]->rect_strt_pnt.y(),pnt.x()-rects[i]->rect_strt_pnt.x(),pnt.y()-rects[i]->rect_strt_pnt.y(),pen);

            pen.setColor(QColor(0,0,0));
            if(rects[i]->rect_strt_pnt.x()>pnt1.x())
               addRect(pnt1.x(),rects[i]->rect_strt_pnt.y(),rects[i]->rect_strt_pnt.x()-pnt1.x(),pnt1.y()-rects[i]->rect_strt_pnt.y(),pen);
            else if(rects[i]->rect_strt_pnt.y()>pnt1.y())
               addRect(rects[i]->rect_strt_pnt.x(),pnt1.y(),pnt1.x()-rects[i]->rect_strt_pnt.x(),rects[i]->rect_strt_pnt.y()-pnt1.y(),pen);
            else if((rects[i]->rect_strt_pnt.x()>pnt1.x()) && (rects[i]->rect_strt_pnt.y()>pnt1.y()))
               addRect(pnt1.x(),pnt1.y(),rects[i]->rect_strt_pnt.x()-pnt1.x(),rects[i]->rect_strt_pnt.y()-pnt1.y(),pen);
            else
               addRect(rects[i]->rect_strt_pnt.x(),rects[i]->rect_strt_pnt.y(),pnt1.x()-rects[i]->rect_strt_pnt.x(),pnt1.y()-rects[i]->rect_strt_pnt.y(),pen);
        }
     }

     if(rect->getMode())
     {
         if(rect->getState()==1)
         {
              pen.setColor(QColor(255,255,255));
              this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
              this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
              this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);

              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addRect(pnt.x(),pnt.y(),rect->pnt.x()-pnt.x(),rect->pnt.y()-pnt.y(),pen);
                   this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
                   this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);


                   pen.setColor(QColor(0,0,0));
                   this->addRect(pnt1.x(),pnt1.y(),rect->pnt.x()-pnt1.x(),rect->pnt.y()-pnt1.y(),pen);
                   this->addRect(pnt1.x()-5.0,pnt1.y()-2.5,5.0,5.0,pen);
                   this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
                   rect->rect_strt_pnt=pnt1;
                   rect->bounding_strt_pnt=pnt1;
                   rect->bounding_end_pnt=rect->rect_end_pnt;
               }
          }

          if(rect->getState()==2)
          {
              pen.setColor(QColor(255,255,255));
              this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
              this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
              this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addRect(rect->pnt.x(),rect->pnt.y(),pnt.x()-rect->pnt.x(),pnt.y()-rect->pnt.y(),pen);
                   this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);

                   pen.setColor(QColor(0,0,0));
                   this->addRect(rect->pnt.x(),rect->pnt.y(),pnt1.x()-rect->pnt.x(),pnt1.y()-rect->pnt.y(),pen);
                   this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt1.x(),pnt1.y()-2.5,5.0,5.0,pen);
                   rect->rect_end_pnt=pnt1;
                   rect->bounding_strt_pnt=rect->rect_strt_pnt;
                   rect->bounding_end_pnt=pnt1;

               }
           }

           if(rect->getState()==3)
           {
               if(pnt1!=pnt)
               {
                    pen.setColor(QColor(255,255,255));
                    this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
                    this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
                    this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
                    rect->translate(pnt,pnt1);

                    pen.setColor(QColor(0,0,0));
                    this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
                    this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
                    this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
                    rect->bounding_strt_pnt=rect->rect_strt_pnt;
                    rect->bounding_end_pnt=rect->rect_end_pnt;

                    draw_Scene();
                }
            }
        }
}

void Graph_Scene::draw_rect_state(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    Scene_Objects* object = new Scene_Objects();

    if(rect->getMode()==false)
    {
        last_pnt=pnt1;
        if(rect->rect_strt_pnt.x()>pnt1.x())
        {
           pnt1.setX(rect->rect_strt_pnt.x());
           rect->rect_strt_pnt.setX(last_pnt.x());
        }

        if(rect->rect_strt_pnt.y()>pnt1.y())
        {
           pnt1.setY(rect->rect_strt_pnt.y());
           rect->rect_strt_pnt.setY(last_pnt.y());
        }

        object->item=addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),pnt1.x()-rect->rect_strt_pnt.x(),pnt1.y()-rect->rect_strt_pnt.y());
        rect->setMode(true);
        rect->setRectEndPnt(pnt1);
        rect->bounding_strt_pnt = rect->rect_strt_pnt;
        rect->bounding_end_pnt = rect->rect_end_pnt;
        object->setObjectPos(rect->rect_strt_pnt,rect->rect_end_pnt);
        this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
        this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
        object->setObjects(2,rects.size()-1);
        objects.push_back(object);
    }

    if(rect->getMode()==true)
    {
        //qDebug()<<"Entered Point "<<rect->getState()<<"\n";

        if(rect->getState()==1)
        {
           //qDebug()<<"Entered Point\n";
           /*pen.setColor(QColor(255,255,255));
           this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
           this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
           this->addRect(pnt1.x(),pnt1.y(),rect->pnt.x()-pnt1.x(),rect->pnt.y()-pnt1.y());*/
           object2->setObjectPos(rect->rect_strt_pnt,rect->rect_end_pnt);
           rect->setState(0);
        }

        if(rect->getState()==2)
        {
            /*pen.setColor(QColor(255,255,255));
            this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
            this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);
            this->addRect(rect->pnt.x(),rect->pnt.y(),pnt1.x()-rect->pnt.x(),pnt1.y()-rect->pnt.y());*/
            object2->setObjectPos(rect->rect_strt_pnt,rect->rect_end_pnt);
            rect->setState(0);
        }

        if(rect->getState()==3)
        {
            /*pen.setColor(QColor(255,255,255));
            this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
            this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
            this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y());*/
            object2->setObjectPos(rect->rect_strt_pnt,rect->rect_end_pnt);
            rect->setState(0);
        }

     }
}

void Graph_Scene::draw_round_rect()
{
    bool k=false;
    QPainterPath path = QPainterPath();
    QPainterPath path1 = QPainterPath();
    QPen pen = QPen();

    QPainter paint;

    if(round_rects.size()==0)
    {
        Draw_RoundRect* round_rect2 = new Draw_RoundRect();
        round_rect2->round_rect_strt_pnt=strt_pnt;
        round_rect=round_rect2;
        temp_round_rect=round_rect2;
        round_rects.push_back(round_rect2);
        //qDebug()<<"enetered and a new rect\n";
    }

    hide_object_edges();

    for(int i=0;i<round_rects.size();i++)
    {

        if((check_object(strt_pnt,round_rects[i]))&&(round_rects[i]->getMode()==true))
        {
             pen.setColor(QColor(0,0,0));
             path.addRect(round_rects[i]->getRoundRectstartPnt().x(),round_rects[i]->getRoundRectstartPnt().y(),5.0,5.0);
             path.addRect(round_rects[i]->getRoundRectendPnt().x(),round_rects[i]->getRoundRectendPnt().y(),5.0,5.0);
             addPath(path,pen);
             round_rect=round_rects[i];
             k=true;
             break;
        }
    }
    if(k==true)
    {
        //qDebug()<<"enetred\n";
       qDebug()<<round_rect->getState();
    }
    else if(round_rect->getMode()==true)
    {
        hide_edges();
        Draw_RoundRect* round_rect2 = new Draw_RoundRect();
        round_rect=round_rect2;
        round_rects.push_back(round_rect2);
        round_rect2->round_rect_strt_pnt=strt_pnt;
        //qDebug()<<"enetered and created a new rect\n";
    }
}

bool Graph_Scene::check_object(QPointF pnt,Draw_RoundRect* round_rect1)
{
    int k=0;
    if(round_rect1->getMode())
    {
       round_rect1->get_strt_edge(pnt);
       round_rect1->get_end_edge(pnt);
       round_rect1->get_line(pnt);
       k=round_rect1->getState();
       if((k==1)||(k==2)||(k==3))
       {
           //qDebug()<<"value of k "<<k;
           return true;
       }
    }
}


void Graph_Scene::draw_round_rect_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    QPainterPath paint_round_rect = QPainterPath();
    QPainterPath paint_round_rect1 = QPainterPath();

     for(int i=0;i<round_rects.size();i++)
     {
        if((pnt1!=pnt)&&(round_rects[i]->getMode()==false))
        {
            pen.setColor(QColor(255,255,255));
            paint_round_rect.addRoundedRect(round_rects[i]->round_rect_strt_pnt.x(),round_rects[i]->round_rect_strt_pnt.y(),pnt.x()-round_rects[i]->round_rect_strt_pnt.x(),pnt.y()-round_rects[i]->round_rect_strt_pnt.y(),round_rects[i]->radius,round_rects[i]->radius,Qt::AbsoluteSize);
            addPath(paint_round_rect,pen);
            pen.setColor(QColor(0,0,0));
            paint_round_rect1.addRoundedRect(round_rects[i]->round_rect_strt_pnt.x(),round_rects[i]->round_rect_strt_pnt.y(),pnt1.x()-round_rects[i]->round_rect_strt_pnt.x(),pnt1.y()-round_rects[i]->round_rect_strt_pnt.y(),round_rects[i]->radius,round_rects[i]->radius,Qt::AbsoluteSize);
            addPath(paint_round_rect1,pen);
        }
     }

     if(round_rect->getMode())
     {
         if(round_rect->getState()==1)
         {
              pen.setColor(QColor(255,255,255));
              paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
              paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
              paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
              addPath(paint_round_rect,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   paint_round_rect.addRoundedRect(pnt.x(),pnt.y(),round_rect->pnt.x()-pnt.x(),round_rect->pnt.y()-pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect.addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0);
                   paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                   addPath(paint_round_rect,pen);

                   pen.setColor(QColor(0,0,0));
                   paint_round_rect1.addRoundedRect(pnt1.x(),pnt1.y(),round_rect->pnt.x()-pnt1.x(),round_rect->pnt.y()-pnt1.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect1.addRect(pnt1.x()-5.0,pnt1.y()-2.5,5.0,5.0);
                   paint_round_rect1.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                   addPath(paint_round_rect1,pen);
                   round_rect->round_rect_strt_pnt=pnt1;
                   round_rect->bounding_strt_pnt=pnt1;
                   round_rect->bounding_end_pnt=round_rect->round_rect_end_pnt;
                   addPath(paint_round_rect1,pen);
               }
          }

          if(round_rect->getState()==2)
          {
              pen.setColor(QColor(255,255,255));
              paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
              paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
              paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
              addPath(paint_round_rect,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   paint_round_rect.addRoundedRect(round_rect->pnt.x(),round_rect->pnt.y(),pnt.x()-round_rect->pnt.x(),pnt.y()-round_rect->pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                   paint_round_rect.addRect(pnt.x(),pnt.y()-2.5,5.0,5.0);
                   addPath(paint_round_rect,pen);

                   pen.setColor(QColor(0,0,0));
                   paint_round_rect1.addRoundedRect(round_rect->pnt.x(),round_rect->pnt.y(),pnt1.x()-round_rect->pnt.x(),pnt1.y()-round_rect->pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                   paint_round_rect1.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                   paint_round_rect1.addRect(pnt1.x(),pnt1.y()-2.5,5.0,5.0);
                   round_rect->round_rect_end_pnt=pnt1;
                   round_rect->bounding_strt_pnt=round_rect->round_rect_strt_pnt;
                   round_rect->bounding_end_pnt=pnt1;
                   addPath(paint_round_rect1,pen);

               }
           }

           if(round_rect->getState()==3)
           {
               if(pnt1!=pnt)
               {
                    pen.setColor(QColor(255,255,255));
                    paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                    paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                    paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                    addPath(paint_round_rect,pen);
                    round_rect->translate(pnt,pnt1);

                    pen.setColor(QColor(0,0,0));
                    paint_round_rect1.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
                    paint_round_rect1.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                    paint_round_rect1.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                    round_rect->bounding_strt_pnt=round_rect->round_rect_strt_pnt;
                    round_rect->bounding_end_pnt=round_rect->round_rect_end_pnt;
                    addPath(paint_round_rect1,pen);
                    draw_Scene();
                }
            }
        }
}

void Graph_Scene::draw_round_rect_state(QPointF pnt,QPointF pnt1)
{
    QPainterPath paint_round_rect = QPainterPath();
    QPen pen = QPen();
    Scene_Objects* object = new Scene_Objects();


    if(round_rect->getMode()==false)
    {
        last_pnt=pnt1;
        round_rect->setMode(true);
        round_rect->setRoundRectEndPnt(pnt1);
        round_rect->bounding_strt_pnt = round_rect->round_rect_strt_pnt;
        round_rect->bounding_end_pnt = round_rect->round_rect_end_pnt;
        object->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
        object->setObjects(5,round_rects.size()-1);
        objects.push_back(object);

        pen.setColor(QColor(0,0,0));
        paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
        paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
        paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
        addPath(paint_round_rect,pen);

    }

    if(round_rect->getMode()==true)
    {
        //qDebug()<<"Entered Point "<<rect->getState()<<"\n";

        if(round_rect->getState()==1)
        {
           //qDebug()<<"Entered Point\n";
           //pen.setColor(QColor(255,255,255));
           //paint_round_rect.addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0);
           //paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
           //paint_round_rect.addRoundedRect(pnt1.x(),pnt1.y(),round_rect->pnt.x()-pnt1.x(),round_rect->pnt.y()-pnt1.y(),5,5,Qt::AbsoluteSize);
           object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
		   //addPath(paint_round_rect,pen);
           round_rect->setState(0);
        }

        if(round_rect->getState()==2)
        {
            /*pen.setColor(QColor(255,255,255));
            paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
            paint_round_rect.addRect(pnt.x(),pnt.y()-2.5,5.0,5.0);*/
            //paint_round_rect.addRoundedRect(round_rect->pnt.x(),round_rect->pnt.y(),pnt1.x()-round_rect->pnt.x(),pnt1.y()-round_rect->pnt.y(),5,5,Qt::AbsoluteSize);
            object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
            //addPath(paint_round_rect,pen);
			round_rect->setState(0);
        }

        if(round_rect->getState()==3)
        {
            /*pen.setColor(QColor(255,255,255));
            paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
            paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
            //paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),5,5,Qt::AbsoluteSize);
            addPath(paint_round_rect,pen);*/
            object5->setObjectPos(round_rect->round_rect_strt_pnt,round_rect->round_rect_end_pnt);
			round_rect->setState(0);
        }

     }
}


void Graph_Scene::draw_ellep()
{
    bool k=false;
    if(elleps.size()==0)
    {
        Draw_ellipse* ellep2 = new Draw_ellipse();
        ellep2->ellep_strt_pnt=strt_pnt;
        ellep=ellep2;
        elleps.push_back(ellep2);
        qDebug()<<"enetered and a new ellipse\n";
    }

    hide_object_edges();

    for(int i=0;i<elleps.size();i++)
    {
        if((check_object(strt_pnt,elleps[i]))&&(elleps[i]->getMode()==true))
        {
             ellep=elleps[i];
             k=true;
             break;
        }
    }
    if(k==true)
    {
        //qDebug()<<"enetred\n";
        qDebug()<<ellep->getState();
    }
    else if(ellep->getMode()==true)
    {
        Draw_ellipse* ellep2 = new Draw_ellipse();
        ellep=ellep2;
        elleps.push_back(ellep2);
        ellep2->ellep_strt_pnt=strt_pnt;
        //qDebug()<<"enetered and created a new ellipse\n";
    }
}

bool Graph_Scene::check_object(QPointF pnt,Draw_ellipse* ellep1)
{
    int k=0;
    if(ellep1->getMode())
    {
       ellep1->get_strt_edge(pnt);
       ellep1->get_end_edge(pnt);
       ellep1->get_line(pnt);
       k=ellep1->getState();
       if((k==1)||(k==2)||(k==3))
       {
           qDebug()<<"value of k1 "<<k;
           return true;
       }
    }
}


void Graph_Scene::draw_ellep_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();

     for(int i=0;i<elleps.size();i++)
     {
        if((pnt1!=pnt)&&(elleps[i]->getMode()==false))
        {
            pen.setColor(QColor(255,255,255));
            addEllipse(elleps[i]->ellep_strt_pnt.x(),elleps[i]->ellep_strt_pnt.y(),pnt.x()-elleps[i]->ellep_strt_pnt.x(),pnt.y()-elleps[i]->ellep_strt_pnt.y(),pen);
            pen.setColor(QColor(0,0,0));
            addEllipse(elleps[i]->ellep_strt_pnt.x(),elleps[i]->ellep_strt_pnt.y(),pnt1.x()-elleps[i]->ellep_strt_pnt.x(),pnt1.y()-elleps[i]->ellep_strt_pnt.y(),pen);
        }
     }

     if(ellep->getMode())
     {
         if(ellep->getState()==1)
         {
              pen.setColor(QColor(255,255,255));
              this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
              this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
              this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);

              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addEllipse(pnt.x(),pnt.y(),ellep->pnt.x()-pnt.x(),ellep->pnt.y()-pnt.y(),pen);
                   this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
                   this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);


                   pen.setColor(QColor(0,0,0));
                   this->addEllipse(pnt1.x(),pnt1.y(),ellep->pnt.x()-pnt1.x(),ellep->pnt.y()-pnt1.y(),pen);
                   this->addRect(pnt1.x()-5.0,pnt1.y()-2.5,5.0,5.0,pen);
                   this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
                   ellep->ellep_strt_pnt=pnt1;
                   ellep->bounding_strt_pnt=pnt1;
                   ellep->bounding_end_pnt=ellep->ellep_end_pnt;
               }
          }

          if(ellep->getState()==2)
          {
              pen.setColor(QColor(255,255,255));
              this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
              this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
              this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
              if(pnt1!=pnt)
              {
                   pen.setColor(QColor(255,255,255));
                   this->addEllipse(ellep->pnt.x(),ellep->pnt.y(),pnt.x()-ellep->pnt.x(),pnt.y()-ellep->pnt.y(),pen);
                   this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);

                   pen.setColor(QColor(0,0,0));
                   this->addEllipse(ellep->pnt.x(),ellep->pnt.y(),pnt1.x()-ellep->pnt.x(),pnt1.y()-ellep->pnt.y(),pen);
                   this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
                   this->addRect(pnt1.x(),pnt1.y()-2.5,5.0,5.0,pen);
                   ellep->ellep_end_pnt=pnt1;
                   ellep->bounding_strt_pnt=ellep->ellep_strt_pnt;
                   ellep->bounding_end_pnt=pnt1;

               }
           }

           if(ellep->getState()==3)
           {
               if(pnt1!=pnt)
               {
                    pen.setColor(QColor(255,255,255));
                    this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
                    this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
                    this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
                    ellep->translate(pnt,pnt1);

                    pen.setColor(QColor(0,0,0));
                    this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
                    this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
                    this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
                    ellep->bounding_strt_pnt=ellep->ellep_strt_pnt;
                    ellep->bounding_end_pnt=ellep->ellep_end_pnt;
                    draw_Scene();
                }
            }
        }
}

void Graph_Scene::draw_ellep_state(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    Scene_Objects* object = new Scene_Objects();

    if(ellep->getMode()==false)
    {
        last_pnt=pnt1;
        object->item=addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),pnt1.x()-ellep->ellep_strt_pnt.x(),pnt1.y()-ellep->ellep_strt_pnt.y());
        ellep->setMode(true);
        ellep->setEllepEndPnt(pnt1);
        ellep->bounding_strt_pnt = ellep->ellep_strt_pnt;
        ellep->bounding_end_pnt = ellep->ellep_end_pnt;
        object->setObjectPos(ellep->ellep_strt_pnt,ellep->ellep_end_pnt);
        this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
        this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
        object->setObjects(3,elleps.size()-1);
        objects.push_back(object);
    }

    if(ellep->getMode()==true)
    {
        //qDebug()<<"Entered Point "<<ellep->getState()<<"\n";

        if(ellep->getState()==1)
        {
           qDebug()<<"Entered Point\n";
           /*pen.setColor(QColor(255,255,255));
           this->addRect(pnt.x()-5.0,pnt.y()-2.5,5.0,5.0,pen);
           this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
           this->addEllipse(pnt1.x(),pnt1.y(),ellep->pnt.x()-pnt1.x(),ellep->pnt.y()-pnt1.y());*/
           object3->setObjectPos(ellep->ellep_strt_pnt,ellep->ellep_end_pnt);
           rect->setState(0);
        }

        if(ellep->getState()==2)
        {
            /*pen.setColor(QColor(255,255,255));
            this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
            this->addRect(pnt.x(),pnt.y()-2.5,5.0,5.0,pen);
            this->addEllipse(ellep->pnt.x(),ellep->pnt.y(),pnt1.x()-ellep->pnt.x(),pnt1.y()-ellep->pnt.y());*/
            object3->setObjectPos(ellep->ellep_strt_pnt,ellep->ellep_end_pnt);
            ellep->setState(0);
        }

        if(ellep->getState()==3)
        {
            /*pen.setColor(QColor(255,255,255));
            this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
            this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
            this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y());*/
            object3->setObjectPos(ellep->ellep_strt_pnt,ellep->ellep_end_pnt);
            ellep->setState(0);
        }

     }
}

void Graph_Scene::draw_polygon()
{
    QPen pen = QPen();
    QBrush brush = QBrush(Qt::SolidPattern);

    pen.setColor(QColor(0,0,0));

    if(polygons.size()==0)
    {
       pnts.push_back(strt_pnt);

       if(mode)
       {
           strt_pnt=strt1_pnt;
           mode=false;

       }
    }

    for(int i=0;i<polygons.size();i++)
    {
        if(polygons[i]->get_draw_mode())
        {
           if(check_object(strt_pnt,polygons[i]))
           {
              polygon=polygons[i];
              polygon_indx=i;
              int pnt_size=polygon->bounding_edge_pnts.size();

              for(int j=0;j<pnt_size;j+=2)
              {
                  QPainterPath paint_path;
                  QPointF pnt=polygon->bounding_edge_pnts[j];
                  QPointF pnt1=polygon->bounding_edge_pnts[j+1];
                  paint_path.addRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());
                  addPath(paint_path,pen,brush);
                  //addRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());
              }

              break;
           }
        }
    }



    if((polygons.size()!=0)&&(polygons[polygons.size()-1]->get_draw_mode())&&(polygon->get_draw_mode()==false))
    {
        pnts.push_back(strt_pnt);
        if(mode)
        {
           strt_pnt=strt1_pnt;
           mode=false;
        }
        draw_polygons();
    }

    //qDebug()<<"Polygons size "<<polygons.size()<<"\n";
}

void Graph_Scene::draw_polygon_move(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();
    QBrush brush = QBrush(Qt::SolidPattern);
    QBrush brush1 = QBrush(Qt::NoBrush);

    QPointF pnt2,pnt3;

    if(polygons.size()==0)
    {
       if((pnt1!=pnt))
       {
         pen.setColor(QColor(255,255,255));
         addLine(strt_pnt.x(),strt_pnt.y(),pnt.x(),pnt.y(),pen);
         pen.setColor(QColor(0,0,0));
         addLine(strt_pnt.x(),strt_pnt.y(),pnt1.x(),pnt1.y(),pen);
       }
    }
     if((polygons.size()!=0)&&(polygons[polygons.size()-1]->get_draw_mode())&&(!polygon->get_draw_mode()))
     {
         if((pnt1!=pnt))
         {
           pen.setColor(QColor(255,255,255));
           addLine(strt_pnt.x(),strt_pnt.y(),pnt.x(),pnt.y(),pen);
           pen.setColor(QColor(0,0,0));
           addLine(strt_pnt.x(),strt_pnt.y(),pnt1.x(),pnt1.y(),pen);
         }
     }

     if(polygon->get_draw_mode())
     {
         if(pnt1!=pnt)
         {
             pen.setColor(QColor(255,255,255));
             for(int j=0;j<polygon->bounding_edge_pnts.size();j+=2)
             {
                 //pnt2=polygon->bounding_edge_pnts[j];
                 //pnt3=polygon->bounding_edge_pnts[j+1];
                 //addRect(pnt2.x(),pnt2.y(),pnt3.x()-pnt2.x(),pnt3.y()-pnt2.y(),pen);
                 QPainterPath paint_path;
                 QPointF pnt=polygon->bounding_edge_pnts[j];
                 QPointF pnt1=polygon->bounding_edge_pnts[j+1];
                 paint_path.addRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());
                 addPath(paint_path,pen,brush1);
             }


             for(int j=0;j<polygon->polygon_pnts.size()-1;j++)
             {
                 addLine(polygon->polygon_pnts[j].x(),polygon->polygon_pnts[j].y(),polygon->polygon_pnts[j+1].x(),polygon->polygon_pnts[j+1].y(),pen);
             }

             addLine(polygon->polygon_pnts[0].x(),polygon->polygon_pnts[0].y(),polygon->polygon_pnts[polygon->polygon_pnts.size()-1].x(),polygon->polygon_pnts[polygon->polygon_pnts.size()-1].y(),pen);

             polygon->translate(pnt,pnt1);

             pen.setColor(QColor(0,0,0));
             for(int j=0;j<polygon->bounding_edge_pnts.size();j+=2)
             {
                 //pnt2=polygon->bounding_edge_pnts[j];
                 //pnt3=polygon->bounding_edge_pnts[j+1];
                 //addRect(pnt2.x(),pnt2.y(),pnt3.x()-pnt2.x(),pnt3.y()-pnt2.y(),pen);
                 QPainterPath paint_path;
                 QPointF pnt=polygon->bounding_edge_pnts[j];
                 QPointF pnt1=polygon->bounding_edge_pnts[j+1];
                 paint_path.addRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());
                 addPath(paint_path,pen,brush1);
             }



             for(int j=0;j<polygon->polygon_pnts.size()-1;j++)
             {
                 addLine(polygon->polygon_pnts[j].x(),polygon->polygon_pnts[j].y(),polygon->polygon_pnts[j+1].x(),polygon->polygon_pnts[j+1].y(),pen);
             }

             addLine(polygon->polygon_pnts[0].x(),polygon->polygon_pnts[0].y(),polygon->polygon_pnts[polygon->polygon_pnts.size()-1].x(),polygon->polygon_pnts[polygon->polygon_pnts.size()-1].y(),pen);
         }
     }


}

bool Graph_Scene::check_object(QPointF pnt, Draw_polygon *polygon1)
{
    int pnt_size=polygon1->get_numberof_polypnts();
    pnt_size=polygon1->bounding_edge_pnts.size();
    int k1=polygon1->point_on_polygon_edges(strt_pnt);
    //int k2=polygon1->check_pnt(strt_pnt);
    if(/*(k2%2!=0)&&(k2<pnt_size)||*/(k1==polygon1->get_numberof_polypnts()+1))
    {
       qDebug()<<"value of k1"<<k1<<"\n";
       return true;
    }
    else
    {
        return false;
    }



}


void Graph_Scene::draw_polygon_state(QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();

    if((pnts.size()>1) && (mode==false)&&(polygon->get_draw_mode()==false))
    {
        last_pnt=pnt1;
        pnts.push_back(pnt1);
        mode=true;
        strt1_pnt=pnt1;
    }

    if(polygon->get_draw_mode())
    {
       qDebug()<<"entered the condition \n";
       polygon=temp_polygon;
       qDebug()<<"polygon mode  "<<polygon->get_draw_mode()<<"\n";
       polygons[polygon_indx]->set_draw_mode(true);
       qDebug()<<"polygons mode  "<<polygons[polygon_indx]->get_draw_mode()<<"\n";
    }
}

void Graph_Scene::draw_polygons()
{
    QPen pen = QPen();
    Draw_polygon *polygon2 = new Draw_polygon();
    pen.setColor(QColor(255,255,255));
    if(polygons.size()!=0)
    {
        for(int i=0;i<polygons.size();i++)
        {
            polygon2=polygons[i];
            //qDebug()<<"polygon boinding point size "<<polygon2->bounding_edge_pnts.size()<<"\n";
            for(int j=0;j<polygon2->bounding_edge_pnts.size();j+=2)
            {
                QPointF pnt=polygon2->bounding_edge_pnts[j];
                QPointF pnt1=polygon2->bounding_edge_pnts[j+1];
                addRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y(),pen);
            }

            for(int j=0;j<polygon2->polygon_pnts.size()-1;j++)
            {
                addLine(polygon2->polygon_pnts[j].x(),polygon2->polygon_pnts[j].y(),polygon2->polygon_pnts[j+1].x(),polygon2->polygon_pnts[j+1].y());
            }
        }
    }
}

void Graph_Scene::setObject(int object_id)
{
    draw_object_state=object_id;
    prev_draw_object_state=object_id;
}


int Graph_Scene::check_intersection(QPointF pnt, QPointF pnt1)
{
     for(int i=0;i<objects.size();i++)
     {
         if((pnt!=objects[i]->ObjectStrtPnt)&&(pnt1!=objects[i]->ObjectEndPnt))
         {
            if((pnt.x()>objects[i]->ObjectStrtPnt.x())&&(pnt.y()>objects[i]->ObjectStrtPnt.y())&&(pnt.x()<objects[i]->ObjectEndPnt.x())&&(pnt.y()<objects[i]->ObjectEndPnt.y())||
               (pnt1.x()>objects[i]->ObjectStrtPnt.x())&&(pnt1.y()>objects[i]->ObjectStrtPnt.y())&&(pnt1.x()<objects[i]->ObjectEndPnt.x())&&(pnt1.y()<objects[i]->ObjectEndPnt.y()))
            {
                if(objects[i]->ObjectId==1)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    return 1;
                }

                if(objects[i]->ObjectId==2)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    qDebug()<<"entered pnt Rect\n";
                    return 2;
                }

                if(objects[i]->ObjectId==3)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    return 3;
                }
           }
        }

     }

}

void Graph_Scene::draw_Scene()
{
    for(int i=0;i<objects.size();i++)
    {
        if((i!=object_indx))
        {
           if(objects[i]->ObjectId==1)
           {
              //qDebug()<<"Entered line\n";
              addLine(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x(),objects[i]->ObjectEndPnt.y());
           }

           if(objects[i]->ObjectId==2)
           {
              addRect(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x()-objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectEndPnt.y()-objects[i]->ObjectStrtPnt.y());
           }

           if(objects[i]->ObjectId==3)
           {
              addEllipse(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x()-objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectEndPnt.y()-objects[i]->ObjectStrtPnt.y());
           }
        }
    }
}

void Graph_Scene::hide_edges()
{
    QPainterPath  path = QPainterPath();
    QPen pen = QPen();
    pen.setColor(QColor(255,255,255));

    if(round_rect->getMode())
    {
        path.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
        path.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
        addPath(path,pen);
    }

}

void Graph_Scene::hide_object_edges()
{
    QPainterPath path = QPainterPath();
    QPen pen = QPen();

    pen.setColor(QColor(255,255,255));

    for(int i=0;i<objects.size();i++)
    {
        if(objects[i]->ObjectId==1)
        {
            if(line->getMode())
            {
                this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
                this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);
            }
        }

        if(objects[i]->ObjectId==2)
        {
            if(rect->getMode())
            {
                this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
                this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
            }
        }

        if(objects[i]->ObjectId==3)
        {
            if(ellep->getMode())
            {
                this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
                this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
            }
        }

        if(objects[i]->ObjectId==5)
        {
            if(round_rect->getMode())
            {
                path.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
                path.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
                addPath(path,pen);
            }
        }
    }

    /*for(int i=0;i<round_rects.size();i++)
    {
        if(round_rects[i]->getMode())
        {
            pen.setColor(QColor(255,255,255));
            path.addRect(round_rects[i]->getRoundRectstartPnt().x(),round_rects[i]->getRoundRectstartPnt().y(),5.0,5.0);
            path.addRect(round_rects[i]->getRoundRectendPnt().x(),round_rects[i]->getRoundRectendPnt().y(),5.0,5.0);
            addPath(path,pen);
        }
    }*/
}

void Graph_Scene::new_Scene()
{
    if(objects.size()!=0)
    {
        clear();
        objects.clear();
    }
}


void Graph_Scene::save_Scene(QString file_name)
{
    QStringList strlist;
    QFile fd(file_name);//It is a datafile from which we are taking the data
    fd.open(QFile::WriteOnly);//checks whther the file is open r not
    QTextStream outputStream(&fd);//reads the data as streams i.e in bytes

    for(int i=0;i<objects.size();i++)
    {
        outputStream<<"ObjectId:"<<" "<<objects[i]->ObjectId<<"\n";
        outputStream<<"Dim:"<<" "<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"\n";
    }

}

void Graph_Scene::save_xml_Scene(QString file_name)
{
    QStringList strlist;
    QFile fd(file_name);//It is a datafile from which we are taking the data
    fd.open(QFile::WriteOnly);//checks whther the file is open r not
    QTextStream outputStream(&fd);//reads the data as streams i.e in bytes

    outputStream<<"<?xml version='1.0'?>"<<"\n";
    outputStream<<"<Object>"<<"\n";

    for(int i=0;i<objects.size();i++)
    {
        if(objects[i]->ObjectId==1)
        {
           outputStream<<"<Type>"<<"Line"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==2)
        {
           outputStream<<"<Type>"<<"Rectangle"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==3)
        {
           outputStream<<"<Type>"<<"Ellipse"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==5)
        {
           outputStream<<"<Type>"<<"Round Rectangle"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

    }

    outputStream<<"</Object>"<<"\n";
}

void Graph_Scene::save_image_Scene()
{
    QPainterPath paint_round_rect;
    QPen pen;

    hide_object_edges();

}

void Graph_Scene::open_Scene(QString file_name)
{
     lines.clear();
     rects.clear();
     elleps.clear();
     objects.clear();
     round_rects.clear();

     bool ok;
     QStringList strlist;
	 QFile fd(file_name);//It is a datafile from which we are taking the data
     fd.open(QFile::ReadOnly);//checks whther the file is open r not
     QTextStream inputStream(&fd);//reads the data as streams i.e in bytes
     QTextStream readline;//reads the line from the stream
     int state;
     QVector<int> attr;
     attr.clear();

     QVector<QString> str;
     str.clear();


     if(file_name.contains(".txt"))
     {
     while(!inputStream.atEnd())
     {
           QString word,words;
           word=inputStream.readLine();//it stores the input into the word

           if(word.contains("ObjectId:",Qt::CaseInsensitive))//it checks whether the word is present r not(rectangle)
           {
               readline.setString(&word,QIODevice::ReadWrite);//it writes a string into stream
               state=1;

           }

           if(word.contains("Dim:",Qt::CaseInsensitive))//it checks whether the word is present r not(rectangle)
           {
               readline.setString(&word,QIODevice::ReadWrite);//it writes a string into stream
               state=2;

           }
           while(!readline.atEnd())
           {
               readline>>words;
               if(!words.isEmpty())
               {
                   if(words.toInt(&ok,10)==0)//it checks whether a number is present r not enters when a number is not present.
                   {
                        qDebug()<<"words "<<words;
                   }
                   else
                   {
                        if(state==1)
                        {
                           int k = words.toInt(&ok,10);
                           if(k==1)
                           {
                             attr.push_back(1);

                           }

                           if(k==2)
                           {
                               attr.push_back(2);


                           }

                           if(k==3)
                           {
                               attr.push_back(3);


                           }
                       }

                        if(state==2)
                        {
                           attr.push_back(words.toInt(&ok,10));
                        }
                   }
                }
            }
            if(attr.size()==5)
            {
                Scene_Objects *object =  new Scene_Objects;
                Draw_Line *line2 = new Draw_Line;
                Draw_rect *rect2 = new Draw_rect;
                Draw_ellipse *ellep2 = new Draw_ellipse;

                if(attr[0]==1)
                {
                    line2->line_strt_pnt.setX(attr[1]);
                    line2->line_strt_pnt.setY(attr[2]);
                    line2->line_end_pnt.setX(attr[3]);
                    line2->line_end_pnt.setY(attr[4]);
                    line2->setState(0);
                    line2->setMode(true);
                    line=line2;
                    lines.push_back(line2);
                }
                if(attr[0]==2)
                {
                    rect2->rect_strt_pnt.setX(attr[1]);
                    rect2->rect_strt_pnt.setY(attr[2]);
                    rect2->rect_end_pnt.setX(attr[3]);
                    rect2->rect_end_pnt.setY(attr[4]);
                    rect2->setState(0);
                    rect2->setMode(true);
                    rect=rect2;
                    rects.push_back(rect2);
                }
                if(attr[0]==3)
                {
                    ellep2->ellep_strt_pnt.setX(attr[1]);
                    ellep2->ellep_strt_pnt.setY(attr[2]);
                    ellep2->ellep_end_pnt.setX(attr[3]);
                    ellep2->ellep_end_pnt.setY(attr[4]);
                    ellep2->setState(0);
                    ellep2->setMode(true);
                    ellep=ellep2;
                    elleps.push_back(ellep2);
                }

                object->ObjectId=attr[0];
                object->ObjectStrtPnt.setX(attr[1]);
                object->ObjectStrtPnt.setY(attr[2]);
                object->ObjectEndPnt.setX(attr[3]);
                object->ObjectEndPnt.setY(attr[4]);
                objects.push_back(object);
                attr.clear();
          }

     }
     for(int i=0;i<objects.size();i++)
     {
         qDebug()<<"ObjectId"<<objects[i]->ObjectId<<"\n";
     }
     //draw_object();

     }

     if(file_name.contains(".xml"))
     {
         qDebug()<<"entered xml file"<<"\n";
         while(!inputStream.atEnd())
         {
               QString word,words;
               word=inputStream.readLine();//it stores the input into the word
			   
               if(word.contains("</Object>"))
                   break;
               if(word.contains("<Type>",Qt::CaseInsensitive))//it checks whether the word is present r not(rectangle)
               {
                   readline.setString(&word,QIODevice::ReadWrite);//it writes a string into stream
                   state=1;

               }

               if(word.contains("<Dim>",Qt::CaseInsensitive))//it checks whether the word is present r not(rectangle)
               {
                   readline.setString(&word,QIODevice::ReadWrite);//it writes a string into stream
                   state=2;

               }
               while(!readline.atEnd())
               {
                   readline>>words;
                   if(!words.isEmpty())
                   {
                       if(words.toInt(&ok,10)==0)//it checks whether a number is present r not enters when a number is not present.
                       {
                            if(words.contains("<Type>")||words.contains("<Dim>"))
                            {
                                str.push_back(words);

                            }
                        }
                        else
                        {
                           if(state==2)
                           {
                                qDebug()<<"words2 "<<words;
                                if(words!="<Dim>" || words!="</Dim>")
                                   attr.push_back(words.toInt(&ok,10));
                           }
                         }
                     }
               }
               if(attr.size()==4)
               {
                   Scene_Objects *object =  new Scene_Objects;
                   Draw_Line *line2 = new Draw_Line;
                   Draw_rect *rect2 = new Draw_rect;
                   Draw_ellipse *ellep2 = new Draw_ellipse;
                   Draw_RoundRect *roundrect2 = new Draw_RoundRect;

                   if(str[0].contains("Line"))
                   {

                       line2->line_strt_pnt.setX(attr[0]);
                       line2->line_strt_pnt.setY(attr[1]);
                       line2->line_end_pnt.setX(attr[2]);
                       line2->line_end_pnt.setY(attr[3]);
                       line2->setState(0);
                       line2->setMode(true);
                       line=line2;
                       lines.push_back(line2);

                       draw_object_state=1;
                       prev_draw_object_state=1;

                       object->ObjectId=1;
                       object->ObjectStrtPnt.setX(attr[0]);
                       object->ObjectStrtPnt.setY(attr[1]);
                       object->ObjectEndPnt.setX(attr[2]);
                       object->ObjectEndPnt.setY(attr[3]);
                       objects.push_back(object);
                   }

                  if(str[0].contains("Rectangle"))
                  {

                      rect2->rect_strt_pnt.setX(attr[0]);
                      rect2->rect_strt_pnt.setY(attr[1]);
                      rect2->rect_end_pnt.setX(attr[2]);
                      rect2->rect_end_pnt.setY(attr[3]);
                      rect2->setState(0);
                      rect2->setMode(true);
                      rect=rect2;
                      rects.push_back(rect2);

                      draw_object_state=2;
                      prev_draw_object_state=2;

                      object->ObjectId=2;
                      object->ObjectStrtPnt.setX(attr[0]);
                      object->ObjectStrtPnt.setY(attr[1]);
                      object->ObjectEndPnt.setX(attr[2]);
                      object->ObjectEndPnt.setY(attr[3]);
                      objects.push_back(object);
                  }
                  if(str[0].contains("Ellipse"))
                  {
                      ellep2->ellep_strt_pnt.setX(attr[0]);
                      ellep2->ellep_strt_pnt.setY(attr[1]);
                      ellep2->ellep_end_pnt.setX(attr[2]);
                      ellep2->ellep_end_pnt.setY(attr[3]);
                      ellep2->setState(0);
                      ellep2->setMode(true);
                      ellep=ellep2;
                      elleps.push_back(ellep2);

                      draw_object_state=3;
                      prev_draw_object_state=3;

                      object->ObjectId=3;
                      object->ObjectStrtPnt.setX(attr[0]);
                      object->ObjectStrtPnt.setY(attr[1]);
                      object->ObjectEndPnt.setX(attr[2]);
                      object->ObjectEndPnt.setY(attr[3]);
                      objects.push_back(object);
                  }

                  if(str[0].contains("RoundRect"))
                  {

                      roundrect2->round_rect_strt_pnt.setX(attr[0]);
                      roundrect2->round_rect_strt_pnt.setY(attr[1]);
                      roundrect2->round_rect_end_pnt.setX(attr[2]);
                      roundrect2->round_rect_end_pnt.setY(attr[3]);
                      roundrect2->setState(0);
                      roundrect2->setMode(true);
                      round_rect=roundrect2;
                      round_rects.push_back(roundrect2);

                      draw_object_state=5;
                      prev_draw_object_state=5;

                      object->ObjectId=5;
                      object->ObjectStrtPnt.setX(attr[0]);
                      object->ObjectStrtPnt.setY(attr[1]);
                      object->ObjectEndPnt.setX(attr[2]);
                      object->ObjectEndPnt.setY(attr[3]);
                      objects.push_back(object);
                  }
                  str.clear();
                  attr.clear();
              }

         }

     }

    draw_object();

}


//copy an object
void Graph_Scene::copy_object()
{

    copy_object1 = new Scene_Objects;
    if((draw_object_state==1)&&(line->getMode()))
    {
        copy_object1->ObjectId=1;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(line->line_end_pnt.x()-line->line_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(line->line_end_pnt.y()-line->line_strt_pnt.y());
        //copy_object1->print();
    }

    if((draw_object_state==2)&&(rect->getMode()))
    {
        copy_object1->ObjectId=2;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(rect->rect_end_pnt.x()-rect->rect_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(rect->rect_end_pnt.y()-rect->rect_strt_pnt.y());
        //copy_object1->print();
    }


    if((draw_object_state==3)&&(ellep->getMode()))
    {
        copy_object1->ObjectId=3;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y());
        //copy_object1->print();
    }

    if((draw_object_state==5)&&(round_rect->getMode()))
    {
        copy_object1->ObjectId=5;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y());
        //copy_object1->print();
    }

}

//cut an object
void Graph_Scene::cut_object()
{

    copy_object1 = new Scene_Objects;
    QPen pen;

    QPainterPath paint_round_rect = QPainterPath();

    pen.setColor(QColor(255,255,255));
    if((draw_object_state==1)&&(line->getMode()))
    {
        copy_object1->ObjectId=1;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(line->line_end_pnt.x()-line->line_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(line->line_end_pnt.y()-line->line_strt_pnt.y());
        //copy_object1->print();

        this->addLine(line->line_strt_pnt.x(),line->line_strt_pnt.y(),line->line_end_pnt.x(),line->line_end_pnt.y(),pen);
        this->addRect(line->getRectStartPnt().x(),line->getRectStartPnt().y(),5.0,5.0,pen);
        this->addRect(line->getRectEndPnt().x(),line->getRectEndPnt().y(),5.0,5.0,pen);

        //removeItem(object1->item);
        objects.remove(object_indx);
        lines.remove(indx);
    }

    if((draw_object_state==2)&&(rect->getMode()))
    {
        copy_object1->ObjectId=2;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(rect->rect_end_pnt.x()-rect->rect_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(rect->rect_end_pnt.y()-rect->rect_strt_pnt.y());

        this->addRect(rect->rect_strt_pnt.x(),rect->rect_strt_pnt.y(),rect->rect_end_pnt.x()-rect->rect_strt_pnt.x(),rect->rect_end_pnt.y()-rect->rect_strt_pnt.y(),pen);
        this->addRect(rect->getRectstartPnt().x(),rect->getRectstartPnt().y(),5.0,5.0,pen);
        this->addRect(rect->getRectendPnt().x(),rect->getRectendPnt().y(),5.0,5.0,pen);
        //copy_object1->print();

        //removeItem(object2->item);
        objects.remove(object_indx);
        rects.remove(indx);
    }


    if((draw_object_state==3)&&(ellep->getMode()))
    {
        copy_object1->ObjectId=3;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y());

        this->addEllipse(ellep->ellep_strt_pnt.x(),ellep->ellep_strt_pnt.y(),ellep->ellep_end_pnt.x()-ellep->ellep_strt_pnt.x(),ellep->ellep_end_pnt.y()-ellep->ellep_strt_pnt.y(),pen);
        this->addRect(ellep->getRectStartPnt().x(),ellep->getRectStartPnt().y(),5.0,5.0,pen);
        this->addRect(ellep->getRectEndPnt().x(),ellep->getRectEndPnt().y(),5.0,5.0,pen);
        //copy_object1->print();

        //removeItem(object3->item);
        objects.remove(object_indx);
        elleps.remove(indx);
    }

    if((draw_object_state==5)&&(round_rect->getMode()))
    {
        copy_object1->ObjectId=5;
        copy_object1->ObjectStrtPnt.setX(0);
        copy_object1->ObjectStrtPnt.setY(0);
        copy_object1->ObjectEndPnt.setX(round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x());
        copy_object1->ObjectEndPnt.setY(round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y());
        //copy_object1->print();

        paint_round_rect.addRoundedRect(round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_strt_pnt.y(),round_rect->round_rect_end_pnt.x()-round_rect->round_rect_strt_pnt.x(),round_rect->round_rect_end_pnt.y()-round_rect->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
        paint_round_rect.addRect(round_rect->getRoundRectstartPnt().x(),round_rect->getRoundRectstartPnt().y(),5.0,5.0);
        paint_round_rect.addRect(round_rect->getRoundRectendPnt().x(),round_rect->getRoundRectendPnt().y(),5.0,5.0);
        addPath(paint_round_rect,pen);


    }


}

//paste an object
void Graph_Scene::paste_object()
{
    hide_object_edges();
    if(copy_object1!=NULL)
    {
       Scene_Objects *object =  new Scene_Objects;
       Draw_Line *line2 = new Draw_Line;
       Draw_rect *rect2 = new Draw_rect;
       Draw_ellipse *ellep2 = new Draw_ellipse;
       Draw_RoundRect *round_rect2 = new Draw_RoundRect;

       QPainterPath paint_round_rect = QPainterPath();

       QPen pen;

       pen.setColor(QColor(0,0,0));

       if(copy_object1->ObjectId==1)
       {
          addLine(strt1_pnt.x(),strt1_pnt.y(),copy_object1->ObjectEndPnt.x()+strt1_pnt.x(),copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          line2->line_strt_pnt.setX(strt1_pnt.x());
          line2->line_strt_pnt.setY(strt1_pnt.y());
          line2->line_end_pnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
          line2->line_end_pnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          line2->setState(0);
          line2->setMode(true);
          lines.push_back(line2);
          object->ObjectId=1;
          object->ObjectStrtPnt.setX(strt1_pnt.x());
          object->ObjectStrtPnt.setY(strt1_pnt.y());
          object->ObjectEndPnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
          object->ObjectEndPnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          objects.push_back(object);

          addLine(strt1_pnt.x(),strt1_pnt.y(),copy_object1->ObjectEndPnt.x()+strt1_pnt.x(),copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          this->addRect(line2->getRectStartPnt().x(),line2->getRectStartPnt().y(),5.0,5.0,pen);
          this->addRect(line2->getRectEndPnt().x(),line2->getRectEndPnt().y(),5.0,5.0,pen);

       }

       if(copy_object1->ObjectId==2)
       {

          rect2->rect_strt_pnt.setX(strt1_pnt.x());
          rect2->rect_strt_pnt.setY(strt1_pnt.y());
          rect2->rect_end_pnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
          rect2->rect_end_pnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          rect2->setState(0);
          rect2->setMode(true);
          rects.push_back(rect2);
          object->ObjectId=2;
          object->ObjectStrtPnt.setX(strt1_pnt.x());
          object->ObjectStrtPnt.setY(strt1_pnt.y());
          object->ObjectEndPnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
          object->ObjectEndPnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
          objects.push_back(object);

          addRect(strt1_pnt.x(),strt1_pnt.y(),copy_object1->ObjectEndPnt.x(),copy_object1->ObjectEndPnt.y());
          this->addRect(rect2->getRectstartPnt().x(),rect2->getRectstartPnt().y(),5.0,5.0,pen);
          this->addRect(rect2->getRectendPnt().x(),rect2->getRectendPnt().y(),5.0,5.0,pen);

       }

       if(copy_object1->ObjectId==3)
       {

           ellep2->ellep_strt_pnt.setX(strt1_pnt.x());
           ellep2->ellep_strt_pnt.setY(strt1_pnt.y());
           ellep2->ellep_end_pnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
           ellep2->ellep_end_pnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
           ellep2->setState(0);
           ellep2->setMode(true);
           elleps.push_back(ellep2);
           object->ObjectId=3;
           object->ObjectStrtPnt.setX(strt1_pnt.x());
           object->ObjectStrtPnt.setY(strt1_pnt.y());
           object->ObjectEndPnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
           object->ObjectEndPnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
           objects.push_back(object);

           addEllipse(strt1_pnt.x(),strt1_pnt.y(),copy_object1->ObjectEndPnt.x(),copy_object1->ObjectEndPnt.y());
           this->addRect(ellep2->getRectStartPnt().x(),ellep2->getRectStartPnt().y(),5.0,5.0,pen);
           this->addRect(ellep2->getRectEndPnt().x(),ellep2->getRectEndPnt().y(),5.0,5.0,pen);

       }

       if(copy_object1->ObjectId==5)
       {

           round_rect2->round_rect_strt_pnt.setX(strt1_pnt.x());
           round_rect2->round_rect_strt_pnt.setY(strt1_pnt.y());
           round_rect2->round_rect_end_pnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
           round_rect2->round_rect_end_pnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
           round_rect2->setState(0);
           round_rect2->setMode(true);
           round_rects.push_back(round_rect2);
           object->ObjectId=5;
           object->ObjectStrtPnt.setX(strt1_pnt.x());
           object->ObjectStrtPnt.setY(strt1_pnt.y());
           object->ObjectEndPnt.setX(copy_object1->ObjectEndPnt.x()+strt1_pnt.x());
           object->ObjectEndPnt.setY(copy_object1->ObjectEndPnt.y()+strt1_pnt.y());
           objects.push_back(object);

           paint_round_rect.addRoundedRect(strt1_pnt.x(),strt1_pnt.y(),round_rect2->round_rect_end_pnt.x()-round_rect2->round_rect_strt_pnt.x(),round_rect2->round_rect_end_pnt.y()-round_rect2->round_rect_strt_pnt.y(),round_rect->radius,round_rect->radius,Qt::AbsoluteSize);
           paint_round_rect.addRect(round_rect2->getRoundRectstartPnt().x(),round_rect2->getRoundRectstartPnt().y(),5.0,5.0);
           paint_round_rect.addRect(round_rect2->getRoundRectendPnt().x(),round_rect2->getRoundRectendPnt().y(),5.0,5.0);
           addPath(paint_round_rect,pen);

       }

    }


}


void Graph_Scene::draw_object()
{

    QPainterPath paint_round_rect = QPainterPath();

    QPen pen;

    pen.setColor(QColor(0,0,0));

    for(int i=0;i<objects.size();i++)
    {
        if(objects[i]->ObjectId==1)
        {
            addLine(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x(),objects[i]->ObjectEndPnt.y());
        }

        if(objects[i]->ObjectId==2)
        {
            addRect(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x()-objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectEndPnt.y()-objects[i]->ObjectStrtPnt.y());
        }

        if(objects[i]->ObjectId==3)
        {
            addEllipse(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x()-objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectEndPnt.y()-objects[i]->ObjectStrtPnt.y());
        }

        if(objects[i]->ObjectId==5)
        {
            paint_round_rect.addRoundedRect(objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectStrtPnt.y(),objects[i]->ObjectEndPnt.x()-objects[i]->ObjectStrtPnt.x(),objects[i]->ObjectEndPnt.y()-objects[i]->ObjectStrtPnt.y(),15,15,Qt::AbsoluteSize);
            addPath(paint_round_rect,pen);
        }
    }

}



QPointF Graph_Scene::getDim()
{

    QPointF dim;

    minPos.setX(objects[0]->ObjectStrtPnt.x());
    minPos.setY(objects[0]->ObjectStrtPnt.y());


    for(int i=1;i<objects.size();i++)
    {
        qDebug()<<objects[i]->ObjectStrtPnt<<"\n";
        qDebug()<<objects[i]->ObjectEndPnt<<"\n";

        if(minPos.x()>objects[i]->ObjectStrtPnt.x())
        {
            minPos.setX(objects[i]->ObjectStrtPnt.x());
        }

        if(minPos.y()>objects[i]->ObjectStrtPnt.y())
        {
            minPos.setY(objects[i]->ObjectStrtPnt.y());
        }
    }

    maxPos.setX(objects[0]->ObjectEndPnt.x());
    maxPos.setY(objects[0]->ObjectEndPnt.y());

    for(int i=1;i<objects.size();i++)
    {
        if(maxPos.x()<objects[i]->ObjectEndPnt.x())
        {
            maxPos.setX(objects[i]->ObjectEndPnt.x());
        }

        if(maxPos.y()<objects[i]->ObjectEndPnt.y())
        {
            maxPos.setY(objects[i]->ObjectEndPnt.y());
        }
    }

    /*minPos=objects[0]->ObjectStrtPnt;
    maxPos=objects[0]->ObjectEndPnt;

    float min_dist=0,max_dist=0,dist=0;

    getDist(minPos,min_dist);
    getDist(maxPos,max_dist);

    for(int i=1;i<objects.size();i++)
    {
       getDist(objects[i]->ObjectStrtPnt,dist);
       if(min_dist>dist)
       {
           minPos=objects[i]->ObjectStrtPnt;
           min_dist=dist;
       }

       getDist(objects[i]->ObjectEndPnt,dist);

       if(max_dist<dist)
       {
          maxPos=objects[i]->ObjectEndPnt;
          max_dist=dist;
       }

    }*/
    qDebug()<<"min Point "<<minPos<<"\n";
    qDebug()<<"max Point "<<maxPos<<"\n";
    //dim=maxPos-minPos;
    dim=maxPos;

    return dim;

}

void Graph_Scene::getDist(QPointF &vertex, float &dist)
{
     dist=sqrt(((vertex.x())*(vertex.x()))+((vertex.y())*(vertex.y())));
}

void Graph_Scene::getObjectsPos(QVector<QPointF> &objectsPos)
{
   
    for(int i=0;i<objects.size();i++)
    {
        objectsPos.push_back(objects[i]->ObjectStrtPnt);
        objectsPos.push_back(objects[i]->ObjectEndPnt);
    }
}


QVector<Scene_Objects*> Graph_Scene::getObjects()
{
    return objects;
}

void Graph_Scene::getMinPosition(QPointF &pnt)
{
    qDebug()<<"min Pos "<<minPos<<"\n";
    qDebug()<<"max Pos "<<maxPos<<"\n";
    pnt=minPos;
}

void Graph_Scene::getMaxPosition(QPointF &pnt1)
{
    pnt1=maxPos;
}
