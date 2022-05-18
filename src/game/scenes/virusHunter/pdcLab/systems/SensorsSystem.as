package game.scenes.virusHunter.pdcLab.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.data.AudioWrapper;
	
	import game.components.entity.Sleep;
	import game.components.hit.Wall;
	import game.scenes.virusHunter.pdcLab.components.SensorMC;
	import game.scenes.virusHunter.pdcLab.components.SensorTargetMC;
	import game.scenes.virusHunter.pdcLab.nodes.SensorsNode;
	
	public class SensorsSystem extends ListIteratingSystem
	{
		public function SensorsSystem($container:DisplayObjectContainer)
		{
			_container = $container;
			super(SensorsNode, updateNode);
		}
		
		private function updateNode($node:SensorsNode, $time:Number):void{
			var trackedEntities:Vector.<Entity> = $node.sensors.trackedEntities;
			var sensors:Vector.<Entity> = $node.sensors.sensors;
			
			for each(var sensor:Entity in sensors){
				for each(var entity:Entity in trackedEntities){
					var mc:MovieClip;
					
					var point:Point = new Point(Spatial(entity.get(Spatial)).x,Spatial(entity.get(Spatial)).y);
					point = _container.localToGlobal(point);
					if(SensorMC(sensor.get(SensorMC)).mc.hitTestPoint(point.x, point.y)){
						if(!SensorMC(sensor.get(SensorMC)).tripped){
							// if not tripped yet - perform tripFunction
							if(SensorTargetMC(sensor.get(SensorTargetMC)).tripFuncName != null){
								// run function
							} else {
								// custom statement(s)
								
								if(SensorMC(sensor.get(SensorMC)).locked == false){
									mc = SensorTargetMC(sensor.get(SensorTargetMC)).mc;
									mc.triggered = true;
									mc.gotoAndPlay("Down");
									mc.doorMech.openBlink.play();
									
									switch(mc.name){
										case "doorA":
											openWall($node.doorWalls.doorWalls[0], $time);
											break;
										case "doorB":
											openWall($node.doorWalls.doorWalls[1], $time);
											break;
										case "doorC":
											openWall($node.doorWalls.doorWalls[2], $time);
											break;
									} 
								} else {
									try{
										mc = SensorTargetMC(sensor.get(SensorTargetMC)).mc;
										mc.doorMech.lockedBlink.play();
										
										var audioComponent:Audio = $node.doorWalls.doorWalls[2].get(Audio);
										audioComponent.playCurrentAction("doorDenied");
										
									} catch(e:Error){
										trace("mc: "+mc);
									}
								}
							}
						}
						SensorMC(sensor.get(SensorMC)).tripped = true;
					} else {
						if(SensorMC(sensor.get(SensorMC)).tripped){
							// if tripped - perform outFunction
							if(SensorTargetMC(sensor.get(SensorTargetMC)).outFuncName != null){
								// run function
							} else {
								// custom statement(s)
								if(SensorMC(sensor.get(SensorMC)).locked == false){
									mc = SensorTargetMC(sensor.get(SensorTargetMC)).mc;
									mc.triggered = false;
									mc.play();
									
									//shellApi.triggerEvent("playDoorSound"); //this throws an error
									
									switch(mc.name){
										case "doorA":
											$node.doorWalls.doorWalls[0].add(new Wall());
											//Sleep($node.doorWalls.doorWalls[0].get(Sleep)).sleeping = false;
											break;
										case "doorB":
											$node.doorWalls.doorWalls[1].add(new Wall());
											//Sleep($node.doorWalls.doorWalls[1].get(Sleep)).sleeping = false;
											break;
										case "doorC":
											$node.doorWalls.doorWalls[2].add(new Wall());
											//Sleep($node.doorWalls.doorWalls[2].get(Sleep)).sleeping = false;
											break;
									}
								}
							}
						}
						SensorMC(sensor.get(SensorMC)).tripped = false;
					}
				}
			}
		}
		
		private function openWall($doorWall:Entity, $time:Number):void{
			/**
			 * Add a delay to the opening of the wall to the door at about 25 frames * time
			 */
			if(_openingWall != $doorWall){
				_openingWall = $doorWall;
				var timer:Timer = new Timer(25*$time*1000, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, removeWall);
				timer.start();
			}
			var audioComponent:Audio = $doorWall.get(Audio);
			audioComponent.playCurrentAction("doorOpened");
			
			function removeWall($event:TimerEvent):void{
				timer.removeEventListener(TimerEvent.TIMER_COMPLETE, removeWall); // [||] Garbage
				$doorWall.remove(Wall);
				//Sleep($doorWall.get(Sleep)).sleeping = true;
				_openingWall = null;
			}
		}
		
		private var _openingWall:Entity;
		private var _container:DisplayObjectContainer;
		private var shellApi:ShellApi;
	}
}