package game.scenes.backlot.cityDestroy.systems
{
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.scenes.backlot.cityDestroy.components.SoldierComponent;
	import game.scenes.backlot.cityDestroy.nodes.SoldierNode;
	import game.systems.GameSystem;
	import game.util.CharUtils;
	
	public class SoldierSystem extends GameSystem
	{
		public function SoldierSystem()
		{
			super( SoldierNode, updateNode );
		}
		
		private function updateNode( node:SoldierNode, time:Number ):void
		{
			var soldier:SoldierComponent = node.soldier;
			var motion:Motion;
			var spatial:Spatial = node.spatial;
			var playerSpatial:Spatial = group.shellApi.player.get( Spatial );
			var motionControl:CharacterMotionControl;
			
			switch( soldier.state )
			{
				case soldier.DEAD:
					soldier.timeDead += time;
					if(soldier.timeDead > soldier.deathTime)
						group.removeEntity(node.entity);
					return;
					break;
				case soldier.IDLE:
					if( playerSpatial.y - spatial.y < 100 )		
					{
						soldier.state = soldier.TURN;
					}
					break;
				
				case soldier.TURN:
					if( soldier.movingLeft )
					{
						CharUtils.moveToTarget( node.entity, soldier.pointA.x, soldier.pointA.y, true, aboutFace );
						soldier.movingLeft = false;
					}
					
					else
					{
						CharUtils.moveToTarget( node.entity, soldier.pointB.x, soldier.pointB.y, true, aboutFace );
						soldier.movingLeft = true;
					}
					
					if( !soldier.speedCheck )
					{
						motionControl = node.entity.get( CharacterMotionControl );
						motionControl.maxVelocityX = 300;
						motionControl.runSpeed = 25;
						motionControl.baseAcceleration = 50;
						soldier.speedCheck = true;
					}
					soldier.state = soldier.MARCHING;
					break;
				
				case soldier.MARCHING:
					break;
				
			}
		}
		
		private function aboutFace( entity:Entity ):void
		{
			var soldier:SoldierComponent = entity.get( SoldierComponent );
		
			soldier.state = soldier.TURN;
		}
		
		
	}
}