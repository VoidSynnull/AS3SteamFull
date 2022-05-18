package game.systems.motion
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.motion.Navigation;
	import game.nodes.motion.NavigationNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.common.displayObjects.Dot;
	
	/**
	 * Manages navigation targets, and whether entity has reached target.
	 * Does not actually move enity towards targets.
	 */
	public class NavigationSystem extends GameSystem
	{
		public function NavigationSystem()
		{
			super( NavigationNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}

		private function updateNode(node:NavigationNode, time:Number):void
		{
			if ( node.navigation.activate )
			{
				activate( node );
				node.navigation.activate = false;
				updateNode( node, time );
				return;
			}
			else if (node.navigation.active)
			{
				var motionControl:MotionControl = node.motionControl;
				var spatial:Spatial = node.spatial;
				var navigation:Navigation = node.navigation;

				// if target has been reached
				if( node.motionTarget.targetReached )
				{	
					// if path has been set, use it to update the next target point
					if( navigation.path != null )
					{
						if ( navigation.index == navigation.path.length - 1 )	// if final point has been reached
						{
							if ( !navigation.loop )
							{
								if ( _debug )	{ updateDebug( node, node.navigation.index + 1 ); }
								
								deactivate( node );
								node.motionTarget.hasNextTarget = false;
							}
							else
							{
								navigation.index = 0;
								updateTarget( node );
								return;
							}
						}
						else
						{
							navigation.index++;
							updateTarget( node );
							return;
						}
					}
					else
					{
						deactivate( node );
					}
				}
			}
		}

		private function activate( node:NavigationNode ):void 
		{
			if ( node.navigation.path != null )
			{
				// for debug mode
				if ( _debug )	{ setupDebug( node ); }
				
				node.navigation.active = true;
				
				if( isNaN(node.navigation.index) )
				{
					node.navigation.index = 0;
					updateTarget( node );
				}

				node.motionTarget.minTargetDelta = node.navigation.minTargetDelta;
				node.motionTarget.checkReached = true;
				node.motionControl.forceTarget = true;
				node.motionControl.inputActive = false;
			}
		}
		
		private function deactivate( node:NavigationNode ):void 
		{
			// reset 
			node.navigation.active = false;
			node.navigation.index = Number.NaN;
			node.navigation.path = null;
		}
		
		/**
		 * Sets target from navigation path, using current index
		 * @param	node
		 */
		private function updateTarget( node:NavigationNode ):void 
		{
			var pathPoint:Point = node.navigation.path[node.navigation.index];
			node.motionTarget.targetX = pathPoint.x;
			node.motionTarget.targetY = pathPoint.y;
			node.motionTarget.hasNextTarget = true;
			
			// for debug mode
			if ( _debug )	{ updateDebug( node, node.navigation.index ); }
		}
		
		/////////////////////////////////////////////////////////////////////////
		///////////////////////////////// DEBUG /////////////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		private function setupDebug( node:NavigationNode ):void 
		{
			resetDebug();

			var container:DisplayObjectContainer = Display(node.entity.get(Display)).container
			for ( var i:int = 0; i < node.navigation.path.length; i++ )
			{
				var dot:Dot = new Dot( 8, 0xFFFB08 );
				var navPoint:Point = node.navigation.path[i];
				dot.x = navPoint.x;
				dot.y = navPoint.y;
				container.addChild( dot );
				_debugPoints.push( dot );
			}
		}
		
		private function resetDebug():void 
		{
			if ( _debugPoints )
			{
				if ( _debugPoints.length > 0 )
				{
					var container:DisplayObjectContainer = DisplayObjectContainer(_debugPoints[i].parent)
					for ( var i:int = 0; i < _debugPoints.length; i++ )
					{
						container.removeChild( _debugPoints[i] );
					}
					_debugPoints.length = 0;
				}
			}
			else
			{
				_debugPoints = new Vector.<Dot>();
			}
		}
		
		private function updateDebug( node:NavigationNode, index:int ):void 
		{
			for ( var i:int = 0; i < index; i++ )
			{
				if(i < _debugPoints.length)
				{
					var dot:Dot = _debugPoints[i];
					dot.color = 0x23EB23;
				}
			}
		}
		
		public function get debug():Boolean		{ return _debug; }
		public function set debug( bool:Boolean ):void
		{
			if ( bool )
			{
				_debug = true;
			}
			else
			{
				_debug = false;
				resetDebug();
			}
		}
		
		private var _debugPoints:Vector.<Dot>;
		private var _debug:Boolean = false;
	}
}
