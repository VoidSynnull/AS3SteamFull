package game.data.animation.entity.character
{
	import ash.core.Entity;

	import game.components.entity.character.Character;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.item.ItemMotion;
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.Animation;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.RigAnimationData;
	import game.systems.timeline.TimelineRigSystem;
	import game.util.CharUtils;

	/**
	 * ...
	 * @author billy
	 */
	public class Default extends Animation
	{
		public const XML_PATH:String = "entity/character/animation/";
		public const TYPE_HUMAN:String = "human/";
		public const TYPE_CREATURE:String = "creature/";
		public const TYPE_PET_BABYQUAD:String = "pet_babyquad/";
		public const TYPE_HORSE:String = "horse/";
		public const TYPE_APE:String = "ape/";
		public const TYPE_BIPED:String = "biped/";

		public var characterXmlPath:String;
		public var creatureXmlPath:String;
		public var petBabyQuadXmlPath:String;
		public var horseXmlPath:String;
		public var apeXmlPath:String;
		public var bipedXmlPath:String;

		public function Default()
		{
		}

		override public function init( data:RigAnimationData ):void
		{
			super.init(data);

			setPartDefault("mouth");
			setPartDefault("eyeState");
		}

		override public function addComponentsTo(entity:Entity):void
		{
			super.addComponentsTo(entity);
		}

		private function setPartDefault( type:String ):void
		{
			// set part type to default is there's no FrameEvent in the first frame already setting it
			for ( var i:uint = 0; i < data.frames[0].events.length; i++ )
			{
				//check for set type
				var frameEvent:FrameEvent = data.frames[0].events[i];
				if ( frameEvent.type == TimelineRigSystem.FRAME_EVENT_SET_PART )
				{
					if (  frameEvent.args[0] == type )
					{
						return;
					}
				}
			}
			data.frames[0].addEvent( new FrameEvent( TimelineRigSystem.FRAME_EVENT_SET_PART, type, SkinPart.DEFAULT_VALUE ) );
		}

		override public function remove(entity:Entity):void
		{
			super.remove(entity);
			// remove components (and systems? --- or do this in animationLoaderSystem?) if they are no longer needed.
		}

		/**
		 * Determines if the character will animate.
		 * Likely used to determine if emitters should be created for the Aniamtion.
		 *
		 * @param entity
		 * @return
		 */
		protected function isAnimateChar(entity:Entity):Boolean
		{
			if( Character( entity.get( Character )).type == CharacterCreator.TYPE_PORTRAIT )
			{
				return false;
			}
			return true;
		}

		///////////////////////////////////////////////////////////////////////
		/////////////////////////////// HELPERS ///////////////////////////////
		///////////////////////////////////////////////////////////////////////

		/**
		 * Turns off or on ItemMotion component.
		 * The ItemMotion component will rotates the item part so that it is always perpendicular to the shoulder joint.
		 * @param entity - character entity
		 * @param turnOff = flag to turn rotate to shoulder on or off.
		 */
		protected function turnOffItemMotion( entity:Entity, turnOff:Boolean = true):void
		{
			var itemPart:Entity = CharUtils.getPart( entity, CharUtils.ITEM );
			if( itemPart )
			{
				var itemMotion:ItemMotion = itemPart.get(ItemMotion);
				if(!itemMotion){
					itemPart.add(new ItemMotion());
					itemMotion = itemPart.get(ItemMotion);
				}
				if(itemMotion)
				{
					if(turnOff)
					{
						itemMotion.state = ItemMotion.ROTATE_TO_SHOULDER;
					}
					else
					{
						itemMotion.state = ItemMotion.NONE;
					}
				}
			}
		}
	}
}
