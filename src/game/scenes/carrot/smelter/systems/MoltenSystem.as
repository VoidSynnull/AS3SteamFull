package game.scenes.carrot.smelter.systems 
{	
	import flash.geom.ColorTransform;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.data.motion.time.FixedTimestep;
	import game.managers.EntityPool;
	import game.scenes.carrot.smelter.components.ConveyorControlComponent;
	import game.scenes.carrot.smelter.components.Molten;
	import game.scenes.carrot.smelter.nodes.MoltenNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class MoltenSystem extends GameSystem
	{
		public function MoltenSystem( conveyorControl:ConveyorControlComponent, pool:EntityPool, total:Dictionary )
		{
			_conveyorControl = conveyorControl;
			_pool = pool;
			_total = total;
			super( MoltenNode, updateNode );
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{	
			super.addToEngine(systemManager);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			_playerDisplay = group.shellApi.player.get( Display );
		}
		
		private function updateNode( node:MoltenNode, time:Number ):void
		{
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			var sleep:Sleep = node.sleep;
			var molten:Molten = node.molten;
			var display:Display = node.display;
			
			var state:String = node.molten.state;
			var currentColor:ColorTransform = display.displayObject.transform.colorTransform;
			var newColor:ColorTransform;
			
			switch( state )
			{
				case molten.FALLING:
					if( motion.y > CONVEYOR_PLACEMENT )
					{
						motion.velocity.y = 0;
						motion.acceleration.y = 0;
						motion.totalVelocity.y = 0;
						
						molten.state = molten.ON_CONVEYOR;
						spatial.y = CONVEYOR_PLACEMENT;	
					}
					
					else
					{
						trace( "current red offset: " + currentColor.redOffset );
						trace( "molten red offset: " + molten.redColor.redOffset );
						
						newColor = new ColorTransform();
						newColor.redOffset += ( molten.redColor.redOffset - currentColor.redOffset ) / 3;
						newColor.greenOffset += ( molten.redColor.greenOffset - currentColor.greenOffset ) / 3;
						newColor.blueOffset += ( molten.redColor.blueOffset - currentColor.blueOffset ) / 3;
						display.displayObject.transform.colorTransform = newColor;
					}
					break;
			
				case molten.ON_CONVEYOR:
					motion.velocity.y = 0;
					motion.acceleration.y = 0;
					motion.totalVelocity.y = 0;
					
					newColor = new ColorTransform();
					
					if( currentColor.redOffset < molten.whiteColor.redOffset )
					{
						newColor.redOffset += 90;
					}
					if( currentColor.greenOffset < molten.whiteColor.greenOffset )
					{
						newColor.greenOffset += 90;
					}
					if( currentColor.blueOffset < molten.whiteColor.blueOffset )
					{
						newColor.blueOffset += 90;
					}
					display.displayObject.transform.colorTransform = newColor;
					
					if( _conveyorControl.moving )
					{
						
						if( motion.velocity.x > MOVER_SPEED )
						{
							motion.velocity.x -= EASING;
						}
						
						else
						{
							motion.velocity.x = MOVER_SPEED;
						}
					}
					
					else  // if paused
					{							
						if( _conveyorControl.stopped )
						{
							EntityUtils.position( node.entity, molten.startX, molten.startY );
							sleep.sleeping = true;
							display.displayObject.transform.colorTransform = molten.originColor;
							
							if( _pool.release( node.entity, MOLTEN ))
							{
								_total[ MOLTEN ]--;
							}
						}
						
						else
						{
							if( motion.velocity.x < 0 )
							{
								motion.velocity.x += EASING;
							}
							else
							{
								motion.velocity.x = 0;
							}
						}
					}
			}
			
			if( node.display.displayObject.hitTestObject( _playerDisplay.displayObject ))
			{
				group.shellApi.triggerEvent( "molten_hit" );
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( MoltenNode );
			super.removeFromEngine( systemManager );
		}
		
		private var _pool:EntityPool;
		private var _total:Dictionary;
		private var _playerDisplay:Display;
		private var _conveyorControl:ConveyorControlComponent;
		
		public static const EASING:uint = 25;
		public static const MOVER_SPEED:int = -250;
		public static const CONVEYOR_PLACEMENT:uint = 755;
		
		private static const MOLTEN:String = "molten";
	}
}