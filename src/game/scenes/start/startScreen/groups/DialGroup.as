package game.scenes.start.startScreen.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.scenes.start.startScreen.components.AgeDial;
	import game.scenes.start.startScreen.systems.AgeDialSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	
	public class DialGroup extends DisplayGroup
	{
		private var display:DisplayObjectContainer;
		public var dialLeft:AgeDial;
		public var dialRight:AgeDial;
		
		public function DialGroup(container:DisplayObjectContainer=null)
		{
			display = container;
			
			super(display.parent);
			
			this.id = "dialGroup";
			this.groupPrefix = "scenes/start/startScreen/groups/dialGroup/";
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			loaded();
		}
		
		override public function destroy():void
		{
			this.display = null;
			
			this.dialLeft 	= null;
			this.dialRight 	= null;
			
			super.destroy();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			var entity:Entity = setUpDialContainer(parent as DisplayGroup, display);
			dialLeft = createDial(entity, display["values"]["left"],"buttonLeftUp","buttonLeftDown").get(AgeDial);
			dialRight = createDial(entity, display["values"]["right"],"buttonRightUp","buttonRightDown").get(AgeDial);
		}
		
		public static function setUpDialContainer(group:DisplayGroup, display:DisplayObjectContainer):Entity
		{
			if(group.getSystem(AgeDialSystem) == null)
				group.addSystem(new AgeDialSystem());
			
			var entity:Entity = EntityUtils.createSpatialEntity(group, display);
			entity.add(new Id(display.name));
			
			var clip:MovieClip = display["values"];
			clip.mask = display["mask"];
			group.convertToBitmap(display["back"]);
			
			return entity;
		}
		
		public static function createDial(dialContainer:Entity, textClone:TextField, forwardButtonName:String, backButtonName:String, font:String = null):Entity
		{
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(dialContainer);
			var entity:Entity = new Entity();
			entity.add(new AgeDial(textClone, font)).add(new Tween());
			
			var clip:MovieClip;
			var buttons:Array = [forwardButtonName, backButtonName];
			
			for each(var name:String in buttons)
			{
				clip = display[name];
				var child:Entity = ButtonCreator.createButtonEntity(clip, dialContainer.group, Command.create(onClick, entity,name == forwardButtonName));
				ToolTipCreator.addToEntity(child);
				var interaction:Interaction = child.get(Interaction);
				interaction.over.add(onOver);
				EntityUtils.addParentChild(child, entity);
			}
			
			EntityUtils.addParentChild(entity, dialContainer, true);
			
			return entity;
		}
		
		private static function onClick(entity:Entity, dialEntity:Entity, up:Boolean):void
		{
			AudioUtils.play(entity.group, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			var dial:AgeDial = dialEntity.get(AgeDial);
			if(up)
				dial.up = true;
			else
				dial.down = true;
		}
		
		private static function onOver(entity:Entity):void
		{
			AudioUtils.play(entity.group, SoundManager.EFFECTS_PATH + "ui_roll_over.mp3", 1, false, SoundModifier.EFFECTS);
		}
		
		public function getValue():String
		{
			return dialLeft.current.text + dialRight.current.text;
		}
	}
}