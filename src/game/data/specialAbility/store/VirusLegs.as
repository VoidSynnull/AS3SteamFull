// Used by:
// Card 3323 using overshirt vh_virus1

package game.data.specialAbility.store 
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.motion.VelocityListener;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.motion.VelocityListenerSystem;
	import game.util.CharUtils;

	/**
	 * Virus leg behavior for virus costume
	 */
	public class VirusLegs extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
						
			partEntity = CharUtils.getPart(node.entity, "overshirt");
			partClip = MovieClip(partEntity.get(Display).displayObject);
			
			if(!node.entity.get(VelocityListener))
			{
				var velocityListener:VelocityListener = new VelocityListener(velocityUpdate, true);
				node.entity.add(velocityListener);	
			}
			// Add the Velocity Listener Sytem if it's not there already
			if( !group.getSystem( VelocityListenerSystem ) )
			{
				group.addSystem( new VelocityListenerSystem() );
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			node.entity.remove(VelocityListener);
		}
		
		public function velocityUpdate(velocityPoint:Point):void
		{	
			var speed:Number = velocityPoint.x / 80;
			_angle -= 4.5 * speed;
			
			if(speed)
			{
				for (var i:Number=0; i<4; i++)
				{
					var vAngle:Number = (_angle - i * 90) * Math.PI / 180;
					var vRotation:Number = 20 * Math.sin(vAngle);
					var vLift:Number = 40 * Math.cos(vAngle);
					var vLeg:MovieClip = MovieClip(partClip.getChildByName("leg" + i));
					vLeg.rotation = baseAngles["leg" + i] + vRotation;
					
					var hinge:MovieClip =  MovieClip(vLeg.getChildByName("hinge"));
					var vPoint:Point = new Point(0, 0);
					vPoint = hinge.localToGlobal(vPoint);
					vPoint = partClip.globalToLocal(vPoint);
					
					var vClaw:MovieClip = MovieClip(partClip.getChildByName("claw" + i));
					vClaw.x = vPoint.x;
					vClaw.y = vPoint.y;
					
					// set claw angle
					var vOffset:Number = (i % 2) * 2;
					if ((speed < 0) && (vLift < 0))
						vRotation += ((1 - vOffset) * vLift);
					else if ((speed > 0) && (vLift > 0))
						vRotation += ((vOffset - 1) * vLift);
					vClaw.rotation = baseAngles["claw" + i] - vRotation;
				}
			}
		}
		
		private var partEntity:Entity;
		private var partClip:MovieClip;
		private var _angle:Number = 0;
		private var baseAngles:Object = {"leg0":-80, "leg1":-100, "leg2":-80, "leg3":-100, "claw0":30, "claw1":150, "claw2":30, "claw3":150};
	}
}