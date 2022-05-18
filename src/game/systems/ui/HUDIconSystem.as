package game.systems.ui 
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.ui.HUDIcon;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.ui.HUDIconNode;
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;
	
	public class HUDIconSystem extends System
	{
		private const NOMINAL_FRAME_DURATION:Number = 0.01666666;

		public var onComplete:Signal;

		private var _nodes:NodeList;
		private var _iconNum:uint;
		
		private var _active:Boolean = false;
		public function get isActive():Boolean { return _active; }
		
		public var spillFlag:Boolean;	// true is spill, false is retract

		public function HUDIconSystem()
		{
			onComplete = new Signal();
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine( systemsManager:Engine ) : void
		{
			_nodes = systemsManager.getNodeList( HUDIconNode );
			reset();
		}
		
		public override function removeFromEngine(systemManager:Engine):void 
		{
			onComplete.removeAll();
			systemManager.releaseNodeList(HUDIconNode);
			_nodes = null;
		}
		
		public function reset():void
		{
			spillFlag = true;
			this.onComplete.removeAll();
			// TODO :: need to reset every node?
		}
		
		public function reverse():void
		{
			spillFlag = !spillFlag;
		}
	
		public function start():void
		{
			_active = true;
		}

		override public function update( time:Number ):void 
		{
			if( _active )
			{
				if( spillFlag )
				{
					spill()
				}
				else
				{
					retract();
				}
			}
		}
		
		private function spill():void 
		{
			var hudIcon:HUDIcon;
			var spatial:Spatial;
			var motion:Motion;
			
			var allComplete:Boolean = true;
			for (var node:HUDIconNode = _nodes.head; null != node; node=node.next) 
			{
				hudIcon = node.icon;
				spatial = node.spatial;
				motion = node.motion;
				
				if( spatial.x != hudIcon.targetX )
				{
					if( !hudIcon.isSpillStart )
					{
						motion.zeroMotion();
						hudIcon.isSpillStart = true;
						hudIcon.isRetractStart = false;
						spatial.scale = HUDIcon.MIN_SCALE;
						motion.velocity.y = hudIcon.vyStart;
					}
					
					motion.velocity.x = ( hudIcon.targetX - spatial.x ) * 3;

					motion.acceleration.y = MotionUtils.GRAVITY;
					if ( motion.y > hudIcon.ground ) 
					{
						spatial.y = hudIcon.ground;
						motion.velocity.y = -motion.velocity.y * .85;	//reverse & dampen velocity on each 'ground' collision
					}
	
					if( spatial.scale < 1 )
					{
						spatial.scale += (1 - spatial.scale) / 8;
					}
		
					if ( Math.abs(spatial.x - hudIcon.targetX) < 1 ) 
					{
						motion.zeroMotion();
						spatial.x = hudIcon.targetX;
						spatial.y = hudIcon.ground;
						spatial.scale = 1;
						hudIcon.isSpillStart = false;
					}
					else
					{
						allComplete = false;
					}
				}
			}
			if( allComplete ) { complete(); }
		}
	
		private function retract():void 
		{
			var hudIcon:HUDIcon;
			var spatial:Spatial;
			var motion:Motion;

			var allComplete:Boolean = true;
			for ( var node:HUDIconNode = _nodes.head; null != node; node=node.next) 
			{
				hudIcon = node.icon;
				spatial = node.spatial;
				motion = node.motion;
				
				if( !hudIcon.isRetractStart )
				{
					hudIcon.isRetractStart = true;
					hudIcon.isSpillStart = false;
					motion.zeroMotion();
					motion.velocity.x = 0;
				}
	
				if( spatial.x != hudIcon.startX )
				{
					// acceleration should continue to apply
					motion.acceleration.x = hudIcon.retractYAccel;
					
					if( spatial.scale > HUDIcon.MIN_SCALE )
					{
						spatial.scale -= (1 - (hudIcon.startX - motion.x)/hudIcon.maxDeltaX) * .03;
					}
					else
					{
						spatial.scale = HUDIcon.MIN_SCALE;
					}
					
					// move to ground, necessary if retract is called before spill is complete
					if( motion.y != hudIcon.ground )
					{
						var delta:Number = hudIcon.ground - motion.y;
						if( delta > .5 )
						{
							motion.y += delta * .2;
						}
						else
						{
							spatial.y = hudIcon.ground;
						}
					}
					
					if ( motion.x >= hudIcon.startX ) 
					{
						motion.zeroMotion();
						spatial.x = hudIcon.startX;
						spatial.y = hudIcon.ground;
						node.display.visible = false;
						hudIcon.isRetractStart = false;
					}
					else
					{
						allComplete = false;
					}
				}
			}
			if( allComplete ) { complete(); }
		}
		
		private function complete():void 
		{
			reverse();
			_active = false;
			onComplete.dispatch();
		}
	}

}
