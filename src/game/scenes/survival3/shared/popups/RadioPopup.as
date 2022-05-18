package game.scenes.survival3.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.Draggable;
	import game.components.motion.TargetSpatial;
	import game.components.render.DynamicWire;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.shared.components.Connector;
	import game.systems.motion.DraggableSystem;
	import game.systems.render.DynamicWireSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class RadioPopup extends Popup
	{
		public function RadioPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/survival3/shared/popups/";
			super.screenAsset = "radioPopup.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			addSystem(new DraggableSystem());
			addSystem(new DynamicWireSystem());
			
			_content = screen.content;
			
			var background:MovieClip = _content.getChildByName("background") as MovieClip;
			var ratio:Number = Math.max(shellApi.viewportWidth / background.width, shellApi.viewportHeight / background.height);
			background.width *= ratio;
			background.height *= ratio;
			
			setUpRadio();
			setUpPageButton();
			setupMetals();
			setupWires();
			setupLemon();
			
			
			super.loadCloseButton();
		}
		
		private function setUpPageButton():void
		{
			var pageButton:MovieClip = _content.getChildByName("pageButton") as MovieClip;
			pageButton.x *= shellApi.viewportWidth / 960;
			pageButton.y *= shellApi.viewportHeight / 640;
			
			if(!shellApi.checkHasItem(_events.BATTERY_NOTE))
			{
				_content.removeChild(pageButton);
			}
			else
			{
				pageButton.mouseChildren = false;
				ButtonCreator.createButtonEntity(pageButton, this, openNote,null, null, null, true, true, 2);
			}			
		}
		
		private function openNote(entity:Entity):void
		{
			addChildGroup(new BatteryNotePopup(this.groupContainer));
		}
		
		private function setupWires():void
		{
			var redStart:MovieClip = _content["redStart"];
			redStart.x *= shellApi.viewportWidth / 960;
			redStart.y *= shellApi.viewportHeight / 640;
			
			var redEnd:MovieClip = _content["redEnd"];
			redEnd.x *= shellApi.viewportWidth / 960;
			redEnd.y *= shellApi.viewportHeight / 640;
			
			var blackStart:MovieClip = _content["blackStart"];
			blackStart.x *= shellApi.viewportWidth / 960;
			blackStart.y *= shellApi.viewportHeight / 640;
			
			var blackEnd:MovieClip = _content["blackEnd"];
			blackEnd.x *= shellApi.viewportWidth / 960;
			blackEnd.y *= shellApi.viewportHeight / 640;
			
			if(!shellApi.checkHasItem(_events.WIRE))
			{
				_content.removeChild(redStart);
				_content.removeChild(redEnd);
				_content.removeChild(blackStart);
				_content.removeChild(blackEnd);
			}
			else
			{
				// Red Wire
				_redEnd = EntityUtils.createSpatialEntity(this, redEnd);
				InteractionCreator.addToEntity(_redEnd, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
				ToolTipCreator.addToEntity(_redEnd);
				originalRed = new Point(redEnd.x, redEnd.y);
				DisplayUtils.moveToTop(redEnd);
				
				var redDraggable:Draggable = new Draggable();
				redDraggable.drag.add(redWireDragged);
				redDraggable.drop.add(redWireDropped);
				_redEnd.add(redDraggable);
				
				_redWire = EntityUtils.createSpatialEntity(this, redStart);
				_redWire.add(new TargetSpatial(_redEnd.get(Spatial)));
				var redDynamic:DynamicWire = new DynamicWire(650, 0xBF3D20, 0, 15, 1);
				_redWire.add(redDynamic);
				
				// Black Wire
				_blackEnd = EntityUtils.createSpatialEntity(this, blackEnd);
				InteractionCreator.addToEntity(_blackEnd, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
				ToolTipCreator.addToEntity(_blackEnd);
				originalBlack = new Point(blackEnd.x, blackEnd.y);
				DisplayUtils.moveToTop(blackEnd);
				
				var blackDraggable:Draggable = new Draggable();
				blackDraggable.dragging.add(blackWireDragged);
				blackDraggable.drop.add(blackWireDropped);
				_blackEnd.add(blackDraggable);
				
				_blackWire = EntityUtils.createSpatialEntity(this, blackStart);
				_blackWire.add(new TargetSpatial(_blackEnd.get(Spatial)));
				var blackDynamic:DynamicWire = new DynamicWire(650, 0x353A40, 0, 15, 1);
				_blackWire.add(blackDynamic);
			}
		}
		
		private function deactivateWires():void
		{
			_redWire.get(DynamicWire).active = false;
			_blackWire.get(DynamicWire).active = false;
		}
		
		private function setupLemon():void
		{
			var lemonMC:MovieClip = _content.getChildByName("lemon") as MovieClip;
			lemonMC.x *= shellApi.viewportWidth / 960;
			lemonMC.y *= shellApi.viewportHeight / 640;
			
			if(!shellApi.checkHasItem(_events.LEMON))
			{
				_content.removeChild(lemonMC);
				_content.removeChild(_content["pennyCover"]);
				_content.removeChild(_content["nailCover"]);
			}
			else
			{
				_content["pennyCover"].x *= shellApi.viewportWidth / 960;
				_content["pennyCover"].y *= shellApi.viewportHeight / 640;
				_content["nailCover"].x *= shellApi.viewportWidth / 960;
				_content["nailCover"].y *= shellApi.viewportHeight / 640;
				
				var lemon:Entity = EntityUtils.createSpatialEntity(this, lemonMC);
				DisplayUtils.bitmapDisplayComponent(lemon);
			}
		}
		
		private function setupMetals():void
		{
			var pennyMC:MovieClip = _content.getChildByName("penny") as MovieClip;
			pennyMC.x *= shellApi.viewportWidth / 960;
			pennyMC.y *= shellApi.viewportHeight / 640;
			
			var nailMC:MovieClip = _content.getChildByName("nail") as MovieClip;
			nailMC.x *= shellApi.viewportWidth / 960;
			nailMC.y *= shellApi.viewportHeight / 640;
			
			// Setup Penny
			if(!shellApi.checkHasItem(_events.PENNY))
			{
				_content.removeChild(pennyMC);
			}
			else
			{
				_penny = EntityUtils.createSpatialEntity(this, pennyMC, _content);
				BitmapTimelineCreator.convertToBitmapTimeline(_penny);
				InteractionCreator.addToEntity(_penny, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
				ToolTipCreator.addToEntity(_penny);
				
				_penny.add(new Connector());
				
				var draggable:Draggable = new Draggable();
				draggable.drop.add(pennyDropped);
				_penny.add(draggable);
			}
			
			// Setup Nail
			if(!shellApi.checkHasItem(_events.NAIL))
			{
				_content.removeChild(nailMC);
			}
			else
			{
				_nail = EntityUtils.createSpatialEntity(this, nailMC, _content);
				BitmapTimelineCreator.convertToBitmapTimeline(_nail);
				InteractionCreator.addToEntity(_nail, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
				ToolTipCreator.addToEntity(_nail);
				
				_nail.add(new Connector());
				
				var dragged:Draggable = new Draggable();
				dragged.drop.add(nailDropped);
				_nail.add(dragged);
			}
		}
		
		private function nailDropped(nail:Entity):void
		{
			var nailSpatial:Spatial = nail.get(Spatial);
			
			if(shellApi.checkHasItem(_events.LEMON))
			{
				if(nailSpatial.x > 640 && nailSpatial.y > 430)
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flesh_impact_04.mp3");
					var nailDisplay:Display = nail.get(Display);
					
					nailSpatial.x = _content["nailCover"].x;
					nailSpatial.y = _content["nailCover"].y;
					DisplayUtils.moveToOverUnder(_content["nailCover"], nailDisplay.displayObject);
					
					nail.get(Draggable).drop.removeAll();
					nail.remove(Draggable);
					EntityUtils.removeInteraction(nail);
					nailDisplay.displayObject.mouseEnabled = false;
					nailDisplay.displayObject.mouseChildren = false;
					nailInLemon = true;
				}
			}
		}
		
		private function pennyDropped(penny:Entity):void
		{
			var pennySpatial:Spatial = penny.get(Spatial);
			
			if(shellApi.checkHasItem(_events.LEMON))
			{	
				// Touching Lemon
				if(pennySpatial.x > 715 && pennySpatial.y > 360 && pennySpatial.y < 580)
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flesh_impact_06.mp3");
					var pennyDisplay:Display = penny.get(Display);
					pennySpatial.x = _content["pennyCover"].x;
					pennySpatial.y = _content["pennyCover"].y;
					DisplayUtils.moveToOverUnder(_content["pennyCover"], pennyDisplay.displayObject);
					
					// Remove interaction and drag
					penny.get(Draggable).drop.removeAll();
					penny.remove(Draggable);			
					pennyDisplay.displayObject.mouseEnabled = false;
					pennyDisplay.displayObject.mouseChildren = false;				
					pennyInLemon = true;
				}
			}
		}
		
		private function redWireDragged(entity:Entity):void
		{
			if(redOnNail)
			{
				_nail.get(Timeline).gotoAndStop("noWire");
				redOnNail = false;
			}
			else if(redOnPenny)
			{
				_penny.get(Timeline).gotoAndStop("noWire");
				redOnPenny = false;
			}
		}
		
		private function redWireDropped(red:Entity):void
		{
			var redDisplay:Display = red.get(Display);
			var redSpatial:Spatial = red.get(Spatial);
			
			//_timedEvent = new TimedEvent(1, 1, deactivateWires);
			//SceneUtil.addTimedEvent(this, _timedEvent);
			
			// Touching penny
			if(_penny != null)
			{
				if(redDisplay.displayObject.hitTestObject(_penny.get(Display).displayObject))
				{
					if(pennyInLemon)
					{
						if(!blackOnPenny)
						{
							redOnPenny = true;
							_penny.get(Timeline).gotoAndStop("wire");
							
							var pennySpatial:Spatial = _penny.get(Spatial);
							
							redSpatial.x = pennySpatial.x;
							redSpatial.y = pennySpatial.y;
							
							AudioUtils.play(this, SoundManager.EFFECTS_PATH + "pick_up_wrapper_02.mp3");
							
							if(blackOnNail)
							{
								completedRadio();
								if(switchOn)
									switchRadio();
							}
							return;
						}
					}
				}
			}
			
			if(_nail != null)
			{
				if(redDisplay.displayObject.hitTestObject(_nail.get(Display).displayObject))
				{
					if(nailInLemon)
					{
						if(!blackOnNail)
						{
							redOnNail = true;
							_nail.get(Timeline).gotoAndStop("wire");
							
							var nailSpatial:Spatial = _nail.get(Spatial);
							
							redSpatial.x = nailSpatial.x;
							redSpatial.y = nailSpatial.y;
							
							AudioUtils.play(this, SoundManager.EFFECTS_PATH + "pick_up_wrapper_02.mp3");
							return;
						}
					}
				}
			}
			redSpatial.x = originalRed.x;
			redSpatial.y = originalRed.y;
		}
		
		private function blackWireDragged(entity:Entity):void
		{		
			if(blackOnNail)
			{
				_nail.get(Timeline).gotoAndStop("noWire");
				blackOnNail = false;
			}
			else if(blackOnPenny)
			{
				_penny.get(Timeline).gotoAndStop("noWire");
				blackOnPenny = false;
			}					
		}
		
		private function blackWireDropped(black:Entity):void
		{
			var blackDisplay:Display = black.get(Display);
			var blackSpatial:Spatial = black.get(Spatial);
			//_timedEvent = new TimedEvent(1, 1, deactivateWires);
			//SceneUtil.addTimedEvent(this, _timedEvent);
			
			// Touching penny
			if(_penny != null)
			{
				if(blackDisplay.displayObject.hitTestObject(_penny.get(Display).displayObject))
				{
					if(pennyInLemon)
					{					
						if(!redOnPenny)
						{
							blackOnPenny = true;
							_penny.get(Timeline).gotoAndStop("wire");
							
							var pennySpatial:Spatial = _penny.get(Spatial);
							
							blackSpatial.x = pennySpatial.x;
							blackSpatial.y = pennySpatial.y;
							
							AudioUtils.play(this, SoundManager.EFFECTS_PATH + "pick_up_wrapper_02.mp3");
							return;
						}
					}
				}
			}
			
			if(_nail != null)
			{
				if(blackDisplay.displayObject.hitTestObject(_nail.get(Display).displayObject))
				{
					if(nailInLemon)
					{
						if(!redOnNail)
						{
							blackOnNail = true;
							_nail.get(Timeline).gotoAndStop("wire");
							
							var nailSpatail:Spatial = _nail.get(Spatial);
							
							blackSpatial.x = nailSpatail.x;
							blackSpatial.y = nailSpatail.y;
							
							AudioUtils.play(this, SoundManager.EFFECTS_PATH + "pick_up_wrapper_02.mp3");
							
							if(redOnPenny)
							{
								completedRadio();
								
								if(switchOn)
									switchRadio();
							}
							return;
						}
					}
				}
			}
			
			blackSpatial.x = originalBlack.x;
			blackSpatial.y = originalBlack.y;
		}
		
		// Setup the radio and switches
		private function setUpRadio():void
		{
			var radio:MovieClip = _content.getChildByName("radio") as MovieClip;
			radio.x *= shellApi.viewportWidth / 960;
			radio.y *= shellApi.viewportHeight / 640;
			
			_radio = EntityUtils.createSpatialEntity(this, radio, _content);
			BitmapTimelineCreator.convertToBitmapTimeline(_radio);
			var time:Timeline = _radio.get(Timeline);
			time.gotoAndStop("off");
			
			for(var i:int = 1; i <= 2; i ++)
			{
				var radioSwitch:Entity = EntityUtils.createSpatialEntity(this, _content["switch"+i], _content);
				BitmapTimelineCreator.convertToBitmapTimeline(radioSwitch);
				time = radioSwitch.get(Timeline);
				time.gotoAndStop("off");
				
				var interaction:Interaction = InteractionCreator.addToEntity(radioSwitch, [InteractionCreator.CLICK]);
				interaction.click.add(Command.create(flipSwitch, i));
				ToolTipCreator.addToEntity(radioSwitch);
			}
		}
		
		private function flipSwitch(radioSwitch:Entity, switchNumber:int):void
		{
			var time:Timeline = radioSwitch.get(Timeline);
			
			if(time.data.getFrame(time.currentIndex).label == "off")
			{
				time.gotoAndStop("on");
				switchOn = true;
			}
			else
			{
				time.gotoAndStop("off");
				switchOn = false;
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "button_02.mp3");
			
			if(switchNumber == 1)
			{
				if(redOnPenny && blackOnNail)
					switchRadio();
			}
		}
		
		private function switchRadio():void
		{
			var radioTimeline:Timeline = _radio.get(Timeline);
			if(switchOn)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "radio_static_01_loop.mp3", 1, true);
				radioTimeline.gotoAndStop("on");
				
				if(_timedEvent == null)
				{
					_timedEvent = new TimedEvent(3, 1, close);
					SceneUtil.addTimedEvent(this, _timedEvent);
				}
			}
			else
			{
				AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "radio_static_01_loop.mp3");
				radioTimeline.gotoAndStop("off");
			}
		}
		
		private function completedRadio():void
		{
			radioComplete = true;
			
			shellApi.triggerEvent(_events.POWERED_RADIO, true);
			shellApi.removeItem(_events.WIRE);
			shellApi.removeItem(_events.LEMON);
			shellApi.removeItem(_events.PENNY);
			shellApi.removeItem(_events.NAIL);
			shellApi.getItem(_events.RADIO);
		}
		
		override public function remove():void
		{
			// show item on remove if radio is complete
			if( radioComplete )
			{
				var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
				itemGroup.showItem(_events.RADIO);
			}

			super.remove()
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			if(_timedEvent)
			{
				_timedEvent.stop();
				_timedEvent = null;
			}			
			
			super.close();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		private var _content:MovieClip;
		
		private var _radio:Entity;
		private var _penny:Entity;
		private var _nail:Entity;
		private var _redEnd:Entity;
		private var _blackEnd:Entity;
		private var _redWire:Entity;
		private var _blackWire:Entity;
		
		private var originalBlack:Point;
		private var originalRed:Point;
		
		private var switchOn:Boolean = false;
		private var batterySetUp:Boolean = false;
		private var pennyInLemon:Boolean = false;
		private var nailInLemon:Boolean = false;
		private var redOnNail:Boolean = false;
		private var redOnPenny:Boolean = false;
		private var blackOnNail:Boolean = false;
		private var blackOnPenny:Boolean = false;
		private var radioOn:Boolean = false;
		private var radioComplete:Boolean = false;
		
		private var _timedEvent:TimedEvent;
		private var _events:Survival3Events;
	}
}