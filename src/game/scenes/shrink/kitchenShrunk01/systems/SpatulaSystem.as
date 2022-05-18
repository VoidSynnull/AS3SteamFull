package game.scenes.shrink.kitchenShrunk01.systems
{
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.scenes.shrink.kitchenShrunk01.nodes.SpatulaNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	import game.util.PointUtils;
	
	public class SpatulaSystem extends GameSystem
	{
		public const DEFAULT_AIR_VEL_X:Number = 500;
		public const DEFAULT_RUN_VEL_X:Number = 800;
		
		public function SpatulaSystem()
		{
			super(SpatulaNode, updateNode, onNodeAdded);
		}
		
		public function onNodeAdded(node:SpatulaNode):void
		{
			node.spatula.headHit.onEnter.add(Command.create(hitHead, node));
			node.spatula.handleHit.onEnter.add(Command.create(hitHandle, node));
		}
		
		private function hitHandle(handle:Entity, hitId:String, node:SpatulaNode):void
		{
			var hitEntity:Entity = group.getEntityById(hitId);
			var hitEntityMotion:Motion = hitEntity.get(Motion);
			
			node.spatula.atMax = false;
			node.motion.rotationVelocity = -hitEntityMotion.lastVelocity.y / (2 * Math.PI);
			
			for (var i:int = 0; i < node.spatula.headHit.hitIds.length; i++)
			{
				var id:String = node.spatula.headHit.hitIds[i];
				var entity:Entity = group.getEntityById(id);
				var motion:Motion = entity.get(Motion);
				// when the player is getting launched need to remove limiters to make jump possible
				var control:CharacterMotionControl = entity.get(CharacterMotionControl);
				if(control != null)
				{
					control.allowAutoTarget = false;
					control.maxAirVelocityX = Number.MAX_VALUE;
					control.maxVelocityX = Number.MAX_VALUE;
					var fsm:FSMControl = entity.get(FSMControl);
				}
				
				motion.velocity = PointUtils.times(node.spatula.headTrajectory, hitEntityMotion.lastVelocity.y * node.spatula.trajectoryAmplification);
				motion.acceleration.y = MotionUtils.GRAVITY;
			}
		}
		
		private function hitHead(head:Entity, hitId:String, node:SpatulaNode):void
		{
			var hitEntity:Entity = group.getEntityById(hitId);
			var hitEntityMotion:Motion = hitEntity.get(Motion);
			node.spatula.atMax = false;
			node.motion.rotationVelocity = hitEntityMotion.lastVelocity.y / ( 2 * Math.PI);
			
			for (var i:int = 0; i < node.spatula.handleHit.hitIds.length; i++)
			{
				var id:String = node.spatula.handleHit.hitIds[i];
				var entity:Entity = group.getEntityById(id);
				var motion:Motion = entity.get(Motion);
				if(motion != null)
				{
					motion.velocity = PointUtils.times(node.spatula.handleTrajectory, hitEntityMotion.lastVelocity.y * node.spatula.trajectoryAmplification);
					motion.acceleration.y = MotionUtils.GRAVITY;
				}
			}
		}
		
		public function updateNode(node:SpatulaNode, time:Number):void
		{
			if(node.spatula.atMax)
				return;
			
			if(node.spatial.rotation > node.spatula.maxRotation && node.motion.rotationVelocity > 0)
			{
				node.spatial.rotation = node.spatula.maxRotation;
				node.spatula.atMax = true;
			}
			
			if(node.spatial.rotation < 0 && node.motion.rotationVelocity < 0)
			{
				node.spatial.rotation = 0;
				node.spatula.atMax = true;
			}
			
			if(node.spatula.headHit.hit)
				node.motion.rotationAcceleration = 0;
			else
				node.motion.rotationAcceleration = -100;
			
			if(node.spatula.atMax)
			{
				node.motion.rotationVelocity = 0;
				node.motion.rotationAcceleration = 0;
				if(node.spatial.rotation > 0)
					node.spatula.atMax = false;
			}
		}
	}
}