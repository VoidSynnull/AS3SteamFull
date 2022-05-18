package game.systems.entity.character.part
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.entity.character.part.pants.Dress;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.part.DressNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	
	/**
	 * The Dress System deals with character pants parts that have a Dress component. The Dress component tells
	 * the system that the character's pants part is a dress that needs to be scaled and rotated depending on
	 * foot/leg position and character speed, respectively.
	 * 
	 * @author Drew Martin
	 */
	public class DressSystem extends GameSystem
	{
		private var startScale:Point = new Point(1, 1); //Hardcoded base scale.
		private var minScale:Point = new Point();
		private var maxScale:Point = new Point();
		private var newScale:Point = new Point();
		
		public function DressSystem()
		{
			super(DressNode, updateNode);
			super._defaultPriority = SystemPriorities.render;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}
		
		private function updateNode(node:DressNode, time:Number):void
		{
			//Rig parts, first check that entity has necessary joint Entities, if not remove Dress component
			var jointEntity:Entity = node.rig.getJoint(CharUtils.FOOT_FRONT);
			if( jointEntity == null ){
				node.entity.remove( Dress );
				return;
			}else{
				var foot1:Spatial = node.rig.getJoint(CharUtils.FOOT_FRONT).get(Spatial);
			}
			//var foot1:Spatial 	= node.rig.getJoint(CharUtils.FOOT_FRONT).get(Spatial);
			var foot2:Spatial 	= node.rig.getJoint(CharUtils.FOOT_BACK).get(Spatial);
			var leg1:Spatial	= node.rig.getJoint(CharUtils.LEG_FRONT).get(Spatial);
			var leg2:Spatial	= node.rig.getJoint(CharUtils.LEG_BACK).get(Spatial);
			
			//Start values
			minScale.setTo(startScale.x, startScale.y * 0.7);
			maxScale.setTo(startScale.x * 1.04, startScale.y);
			newScale.setTo(0, 0);

			/**
			 * Calculates the dress's new X scale based on the ratio of the distance
			 * between both feet's X value and the base distance between them (18.36).
			 */
			var x:Number = Math.abs(foot1.x - foot2.x) * 0.36;
			newScale.x = (x / 18.36) * startScale.x;
			
			if(newScale.x > maxScale.x)			newScale.x 	= maxScale.x;
			else if(newScale.x < minScale.x)	newScale.x 	= minScale.x;
			//node.addition.scaleX = newScale.x - startScale.x;
			
			/**
			 * Calculates the dress's new Y scale based on the ratio of the max distance
			 * between foot/leg Y values and the base distance between them (24.7).
			 */
			var y:Number = Math.max(Math.abs(foot1.y - leg1.y) * 0.36, Math.abs(foot2.y - leg2.y) * 0.36);
			newScale.y = (y / 24.7) * startScale.y;
			
			if(newScale.y > maxScale.y)			newScale.y 	= maxScale.y;
			else if(newScale.y < minScale.y)	newScale.y 	= minScale.y;
			//node.addition.scaleY = newScale.y - startScale.y;
			
			/**
			 * Don't think this is needed, since scaling of parts is dependent on the parent DisplayObject anyway.
			 */
			/*
			//Scaling based on parent
			var container:DisplayObjectContainer = dress.displayObject.parent;
			if(container.scaleY > 1 && dress.displayObject.scaleY > maxScale.y - (container.scaleY - 1) * maxScale.y / 1)
			dress.displayObject.scaleY = maxScale.y - (container.scaleY - 1) * (maxScale.y / 1);
			*/
			
			/**
			 * Gets the Motion component of the parent Entity (the character) to calculate
			 * the dress's rotation based on velocity.x. 
			 */
			var motion:Motion = Parent(node.entity.get(Parent)).parent.get(Motion);
			if(!motion) return;
			
			if(motion.velocity.length == 0) node.addition.rotation = 0;
			else
			{
				node.addition.rotation = -Math.abs(motion.velocity.x * 0.01);
				
				/**
				 * Capped the rotation out at -15. Otherwise the dress will rotate too much and the view of
				 * Poptropican "private parts" will be forever burned into your retinas... I wish that upon no one.
				 */
				//if(node.addition.rotation < -15) node.addition.rotation = -10;
			}
		}
	}
}
