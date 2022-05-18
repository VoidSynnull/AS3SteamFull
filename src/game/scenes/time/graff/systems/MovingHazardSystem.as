package game.scenes.time.graff.systems
{	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.motion.Threshold;
	import game.scenes.time.graff.nodes.MovingHazardNode;
	import game.systems.GameSystem;
	
	public class MovingHazardSystem extends GameSystem
	{
		private var _usePoints:Boolean = false;
		private var _movingLeft:Boolean = true;
		/**
		 * system to manage hazard hits that move between two points in a loop
		 */
		public function MovingHazardSystem(usePoints:Boolean=false)
		{
			_usePoints = usePoints;
			super(MovingHazardNode, updateNode, addNode);
		}
		
		public function updateNode(node:MovingHazardNode, time:Number):void
		{
			// manual hit test for audio triggering
			var motion:Motion = node.motion;
			var playerDisplay:Display = group.shellApi.player.get( Display );	
			if (playerDisplay.displayObject.hitTestPoint(group.shellApi.offsetX(motion.x), group.shellApi.offsetY(motion.y), false))
			{				
				group.shellApi.triggerEvent( "hitHazard" ); // to trigger a sound in xml
			}	
			if(node.movingHazard.isDart == true)
			{
				var visible:Entity = node.movingHazard.visible;
				var spatial:Spatial = visible.get( Spatial );
				if(node.motion.x > node.movingHazard.rightThreshHold && node.motion.velocity.x > 0)
				{
					node.motion.x = node.movingHazard.startingLocation.x;
					node.motion.y = node.movingHazard.startingLocation.y;
				}
				if(node.motion.x < node.movingHazard.leftThreshHold && node.motion.velocity.x < 0)
				{
					node.motion.x = node.movingHazard.startingLocation.x;
					node.motion.y = node.movingHazard.startingLocation.y;
				}
			}
			if(_usePoints && node.movingHazard.isDart == false) {
				var visible2:Entity = node.movingHazard.visible;
				var spatial2:Spatial = visible.get( Spatial );
				if(node.motion.x > node.movingHazard.rightThreshHold && _movingLeft == true) {
					trace("now move left");
					node.motion.velocity.x = -node.motion.velocity.x;
					spatial2.scaleX = -spatial2.scaleX;
					_movingLeft = false;
				}
				if(node.motion.x < node.movingHazard.leftThreshHold && _movingLeft == false) {
					trace("now move right");
					node.motion.velocity.x = -node.motion.velocity.x;
					spatial2.scaleX = -spatial2.scaleX;
					_movingLeft = true;
				}
			}
		}
		
		public function addNode(node:MovingHazardNode):void
		{
			if(_usePoints == false) {
				node.threshHold.threshold = node.movingHazard.leftThreshHold;
				node.threshHold.entered.addOnce( Command.create( moveHazard, true , node, node.movingHazard.leftThreshHold, node.movingHazard.rightThreshHold ));
				node.entity.remove( Sleep );
			}
		}
		
		private function moveHazard( moveLeft:Boolean , node:MovingHazardNode , x1:Number, x2:Number):void
		{
			var visible:Entity = node.movingHazard.visible;
			var hit:Entity = node.entity;
			var spatial:Spatial = visible.get( Spatial );
			
			if ( moveLeft )
			{
				node.threshHold = new Threshold( "x", "<" );
				node.threshHold.threshold = x1;
				node.threshHold.entered.addOnce( Command.create( moveHazard, false, node, x1, x2 ));
			}
			else
			{
				node.threshHold = new Threshold( "x", ">" );
				node.threshHold.threshold = x2;
				node.threshHold.entered.addOnce( Command.create( moveHazard, true, node, x1, x2 ));
			}
			
			node.motion.velocity.x = -node.motion.velocity.x;
			spatial.scaleX = -spatial.scaleX;
			hit.add( node.threshHold );
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	};
};