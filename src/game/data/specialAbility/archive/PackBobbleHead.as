// Status: retired
// Usage (1) ads
// Used by avatar pack ad_meatballs2_steve

package game.data.specialAbility.character 
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

	/*
	 * Custom Special Ability for bobble head on character on avatar back
	 *
	*/
	
	public class PackBobbleHead extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{	
			super.init(node);
			
			partEntity = CharUtils.getPart(node.entity, "pack");
			//headEntity = CharUtils.getPart(node.entity, CharUtils.HEAD_PART);
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
			if (velocityPoint.y != 0)
			{
				r += velocityPoint.y/3;
			}else if (velocityPoint.x != 0)
			{
				r += velocityPoint.x/3;
			}

			
			var ar:Number = -r/2;
			vr += ar;
			vr *= damp;
			r += vr;
			
			if (r > rLimit)
			{
				r = rLimit;
			} else if (r < -rLimit)
			{
				r = -rLimit;
			}
			
			var vHead:MovieClip = MovieClip(partClip.getChildByName("followHead"));
			vHead.rotation = r;
			
		}
		
		private var partEntity:Entity;
		private var headEntity:Entity;
		private var partClip:MovieClip;
		private var damp:Number = 0.7;
		private var vr:Number = 0;
		private var r:Number = 0;
		private var dir:Number = 1;
		private var rLimit:Number = 130;
		//private var _angle:Number = 0;
		//private var baseAngles:Object = {"leg0":-80, "leg1":-100, "leg2":-80, "leg3":-100, "claw0":30, "claw1":150, "claw2":30, "claw3":150};
	}
}