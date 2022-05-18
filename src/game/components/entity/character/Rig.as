package game.components.entity.character
{	

	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.part.Joint;
	import game.components.entity.character.part.Part;;
	import game.data.animation.entity.RigData;
	
	import org.osflash.signals.Signal;
	
	public class Rig extends Component
	{
		public var data:RigData;
		public var parts:Dictionary;	// Dictionary of part Entities, see PartCreator
		public var joints:Dictionary;	// Dictionary of joint Entities, see JointCreator
		public var type:String;
		public var path:String;
		public var partNames:Vector.<String>;

		public var partsLoadingComplete:Signal;
		
        public function Rig()
		{
			parts 		= new Dictionary(true);
			joints 		= new Dictionary(true);
			partNames 	= new Vector.<String>();
			partsLoadingComplete = new Signal();
		}
		
		override public function destroy():void
		{
			parts = null;
			joints = null;
			partNames = null;
			
			super.destroy();
		}
		
		//////////////////// Joints ////////////////////
		
		public function addJoint( joint:Entity ):void
		{
			joints[joint.get(Id).id] = joint;
		}
		
		public function getJoint(name:String):Entity
		{
			var joint:Entity = Entity( joints[ Joint.PREFIX + name] );
			if ( joint != null )
			{
				return joint;
			}
			else
			{
				//trace("Error :: Rig :: getJoint :: Joints for " + name + " not found." );
				return null;
			}
		}
		
		/**
		 * Pause or unpause all joints
		 * @param	bool
		 */
		public function jointsSleeping( bool:Boolean = true ):void
		{
			var sleep:Sleep;
			
			for each( var jointEntity:Entity in joints )
			{
				sleep = jointEntity.get(Sleep);
				
				if(sleep)
				{
					sleep.sleeping = bool;
				}
			}
		}
		
		/**
		 * Remove sleep
		 */
		public function removeSleep():void
		{
			for each( var jointEntity:Entity in joints )
			{
				jointEntity.remove(Sleep);
			}
		}
		
		//////////////////// Parts ////////////////////
		
		public function addPart(partEntity:Entity):void
		{
			var part:Part = partEntity.get(Part) as Part;
			parts[part.id] = partEntity;
			partNames.push(part.id);
		}
		
		public function getPart(type:String):Entity
		{
			return parts[type] as Entity
		}
		
		public function getDisplay(name:String):Display
		{
			var entity:Entity = getPart( name );
			if ( entity != null )
			{
				var display:Display = Display(entity.get(Display));
				if ( display != null )
				{
					return display;
				}
			}
			return null;
		}
		
		/**
		 * Pause or unpause all joints
		 * @param	bool
		 */
		public function partsSleeping( bool:Boolean = true ):void
		{
			for each( var partEntity:Entity in parts )
			{
				Sleep( partEntity.get(Sleep) ).sleeping = bool;
				Sleep( partEntity.get(Sleep) ).ignoreOffscreenSleep = bool;
			}
		}
	}
}