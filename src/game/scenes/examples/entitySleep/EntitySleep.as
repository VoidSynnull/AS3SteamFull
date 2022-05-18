package game.scenes.examples.entitySleep
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.engine.Sparks;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class EntitySleep extends PlatformerGameScene
	{
		public function EntitySleep()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/entitySleep/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_childGroup = new Group();
			super.addChildGroup(_childGroup);
			
			var parent:Entity;
			var clip:MovieClip = super._hitContainer as MovieClip;
			
			parent = addCounter(clip.counter1, "both");
			parent = addCounter(clip.counter1.child, null, parent);
			addCounter(clip.counter1.child.child, null, parent);
			
			parent = addCounter(clip.counter2, "onlyOnPause");
			parent = addCounter(clip.counter2.child, null, parent);
			addCounter(clip.counter2.child.child, null, parent);
			
			parent = addCounter(clip.counter3, "never");
			parent = addCounter(clip.counter3.child, null, parent);
			addCounter(clip.counter3.child.child, null, parent);
			
			parent = addCounter(clip.counter4, "both", null, _childGroup);
			parent = addCounter(clip.counter4.child, null, parent, _childGroup);
			addCounter(clip.counter4.child.child, null, parent, _childGroup);
			
			// create an offscreen point as a parent which will determine if the child Entity's counter ticks.  
			//   The sleep system will use its Spatial to determine sleep
			//   rather than its Display since its Display has an area of zero.  It will also use the Spatial if 
			//   an Entity doesn't have a Display at all, or a Display with no container (not added yet).
			var offscreenPointX:int = 1800;
			var offscreenPointY:int = 700;
			parent = new Entity();
			parent.add(new Sleep());
			parent.add(new Spatial(offscreenPointX, offscreenPointY));
			var empty:Sprite = new Sprite();
			super.hitContainer.addChild(empty);
			parent.add(new Display(empty));
			super.addEntity(parent);
			addCounter(clip.counter5, null, parent);
			
			super.addSystem(new TimeCounterSystem(), SystemPriorities.update);
			
			var sparks:Sparks = new Sparks();
			
			sparks.init();
			var particleEntity:Entity = EmitterCreator.create(this, super.hitContainer, sparks, 1800, 700);
			particleEntity.add(new Sleep());
			
			addButtons();
		}
		
		private function addCounter(container:DisplayObjectContainer, type:String, parent:Entity = null, group:Group = null):Entity
		{
			if(group == null)
			{
				group = this;
			}
			
			var entity:Entity = new Entity();
			
			entity.add(new Display(container));
			entity.add(new TimeCounter());
			entity.add(new Spatial());
			
			if(parent == null)
			{
				var sleep:Sleep = new Sleep();
				
				if(type == "onlyOnPause")
				{
					entity.ignoreGroupPause = false;
					sleep.ignoreOffscreenSleep = true;
				}
				else if(type == "never")
				{
					entity.ignoreGroupPause = true;
					sleep.ignoreOffscreenSleep = true;
				}
				else if(type == "both")
				{
					entity.ignoreGroupPause = false;
					sleep.ignoreOffscreenSleep = false;
				}
				
				entity.add(sleep);
			}
			else
			{
				EntityUtils.addParentChild(entity, parent);
			}
			
			group.addEntity(entity);
			
			return(entity);
		}
		
		private function addButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0xD5E1FF);
			var button:Entity;
			
			button = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).togglePauseButton, this, togglePause );
			button.add(new Sleep(false, true));
			button.ignoreGroupPause = true;
			ButtonCreator.addLabel( MovieClip(super._hitContainer).togglePauseButton, "Toggle Pause", labelFormat, ButtonCreator.ORIENT_CENTERED);
	
			button = ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).toggleChildGroupPauseButton, this, toggleChildGroupPause );
			button.add(new Sleep(false, true));
			button.ignoreGroupPause = true;
			ButtonCreator.addLabel( MovieClip(super._hitContainer).toggleChildGroupPauseButton, "Toggle Child Group Pause", labelFormat, ButtonCreator.ORIENT_CENTERED);

		}
		
		private function togglePause(...args):void
		{
			if(!super.paused)
			{
				super.pause();
			}
			else
			{
				super.unpause();
			}
		}
		
		private function toggleChildGroupPause(...args):void
		{
			if(!_childGroup.paused)
			{
				_childGroup.pause();
			}
			else
			{
				_childGroup.unpause();
			}
		}
		
		private var _childGroup:Group;
	}
}