package game.scenes.time.viking.systems
{
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.scenes.time.viking.components.LightningFlash;
	import game.scenes.time.viking.nodes.LightningFlashNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
		
	public class LightningFlashSystem extends GameSystem
	{
		public function LightningFlashSystem()
		{
			_defaultPriority = SystemPriorities.update;
			super(LightningFlashNode, updateNode, addNode, removeNode);
		}
		public override function addToEngine(engine:Engine):void
		{
			super.addToEngine(engine);
		}

		private function addNode(node:LightningFlashNode):void
		{
			var lightning:LightningFlash = node.lightningFlash;
			var lightningEnt:Entity = node.entity;	
			lightning.delay = Math.ceil(Math.random()*10);
			SceneUtil.addTimedEvent(group, new TimedEvent(lightning.delay,1,Command.create(startLightningFlash, node)),"thunderTIME");		
		}
		
		private function removeNode(node:LightningFlashNode):void
		{
			var lightning:LightningFlash = node.lightningFlash;
			var display:Display = node.display;
			stop(lightning, display.displayObject);
		}
		
		private function updateNode(node:LightningFlashNode, time:Number):void
		{
			var lightning:LightningFlash = node.lightningFlash;
			var lightningEnt:Entity = node.entity;
			var display:DisplayObject = EntityUtils.getDisplayObject(lightningEnt);	
			if(!stopped){
				if( !lightning.stopped )
				{
					if(lightning.flashing)
					{
						if(lightning.flashCount < flashLimit){
							lightning.flashCount++;					
							if(display.transform.colorTransform.color == lightning.startColorTrans.color){
								colorize(display, lightning.flashingColorTrans.color, 0.5);
							}else{
								colorize(display, 0 ,0);
							}			
						}
						else
						{
							lightning.flashing = false;
							lightning.flashCount = 0;
							colorize(display, 0, 0);
						}
					}
				}
				else{
					stop(lightning, display);
				}
			}
			else{
				stop(lightning, display);
			}

		}
		
		private function stop(lightning:LightningFlash, display:DisplayObject):void
		{
			if(lightning.flashing){
				if(display.transform.colorTransform.color == lightning.startColorTrans.color){
					lightning.flashing = false;
					lightning.flashCount = 0;
					colorize(display, 0, 0);
				}
				nextFlashTimer.stop();
			}
		}	
		
		private function startLightningFlash(node:LightningFlashNode):void
		{
			var lightning:LightningFlash = node.lightningFlash;
			if(!stopped){
				var lightningEnt:Entity = node.entity;
				lightning.flashing = true;
				// sound
				group.shellApi.triggerEvent(lightning.soundEvent);
				lightning.delay = Math.ceil(Math.random()*lightning.flashDelayRange);
				nextFlashTimer = SceneUtil.addTimedEvent(group, new TimedEvent(lightning.delay,1,Command.create(startLightningFlash, node)),"thunderTIME");	
			}
		}
		
		private function colorize(display:DisplayObject, color:uint, alpha:Number = 1):void
		{
			var white:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0, 0, 0, 0 );
			white.redOffset = (color >> 16) & 0xFF;
			white.greenOffset = (color >> 8) & 0xFF;
			white.blueOffset = color & 0xFF;
			white.alphaOffset = alpha;
			display.transform.colorTransform = white;
		}

		private var flashLimit:Number = 6;
		private var flickerDelay:Number = 3;
		private var nextFlashTimer:TimedEvent;
		public var stopped:Boolean = false;
		
	};
};