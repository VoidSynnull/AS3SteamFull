package game.data.animation.entity.character 
{
	import ash.core.Entity;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.group.Group;
	import engine.managers.GroupManager;
	import engine.components.Spatial;
	import flash.display.DisplayObjectContainer;
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.Steam;
	import game.util.CharUtils;
	import game.systems.ParticleSystem;
	
	/**
	 * ...
	 * @author billy/bard
	 */
	public class Angry extends Default
	{
		private const LABEL_START_ANGER:String = "startAnger";
		private const LABEL_STOP_ANGER:String = "stopAnger";
		
		public function Angry()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "angry" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var leftSteam:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			var rightSteam:Entity = _groupManager.getEntityById(_emitterID_R, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if(leftSteam == null)
			{
				addTears(entity, _emitterID_L);
			}
			else
			{
				leftSteam.get(Emitter).remove = false;
			}
			
			if(rightSteam == null)
			{
				addTears(entity, _emitterID_R);
			}
			else
			{
				rightSteam.get(Emitter).remove = false;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var leftSteam:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			var rightSteam:Entity = _groupManager.getEntityById(_emitterID_R, null, entity); 

			//check label
			if ( label == LABEL_START_ANGER )
			{
				Steam(leftSteam.get(Emitter).emitter).rate = STEAM_RATE;
				Steam(rightSteam.get(Emitter).emitter).rate = STEAM_RATE;
				
				// TODO :: Need to add color change for head skin here as well
			}
			else if ( label == LABEL_STOP_ANGER )
			{
				Steam(leftSteam.get(Emitter).emitter).rate = 0;
				Steam(rightSteam.get(Emitter).emitter).rate = 0;
				
				// TODO :: Need to stop color change for head skin here as well
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var leftSteam:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			leftSteam.get(Emitter).remove = true;
			var rightSteam:Entity = _groupManager.getEntityById(_emitterID_R, null, entity);
			rightSteam.get(Emitter).remove = true;
		}
		
		private function addTears(character:Entity, id:String):void
		{
			// set target
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			// set offset & direction
			var offsetX:int;
			var direction:int;
			if(id == _emitterID_L)
			{
				offsetX = -60;
				direction = -1;
			}
			else
			{
				offsetX = 54;
				direction = 1;
			}
			
			// create emitter entity
			var steam:Steam = new Steam()
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, steam, offsetX, 0, character, id, followTarget);
			steam.init(direction);
		}
		
		[Inject]
		public var _groupManager:GroupManager;
		
		private const STEAM_RATE:Number = 10;
		
		private var _emitterID_L:String = "leftSteam";
		private var _emitterID_R:String = "rightSteam";
	}
}