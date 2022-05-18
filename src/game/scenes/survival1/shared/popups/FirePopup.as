package game.scenes.survival1.shared.popups
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.motion.SpatialToMouse;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.data.sound.SoundModifier;
	import game.data.ui.TransitionData;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.shared.components.BitmapClean;
	import game.scenes.survival1.shared.particles.CampFire;
	import game.scenes.survival1.shared.particles.FlintSparks;
	import game.scenes.survival1.shared.systems.BitmapCleanSystem;
	import game.systems.motion.SpatialToMouseSystem;
	import game.ui.popup.HandBookPopup;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.twoD.renderers.BitmapRenderer;
	
	public class FirePopup extends Popup
	{
		//There is no "Flint and Striker" item, so I'm just adding constants for ease of use.
		private const FLINT_AND_STRIKER:String 	= "flintAndStriker";
		private const BLOW_FIRE:String 			= "blowFire";
		private const RESTART:String			= "restart";
		private const CLOSE_POPUP:String		= "closePopup";
		
		private var PARTICLE_RATE_INCREASE:int 	= 10;
		private var PARTICLE_RATE_START:int 	= 4;
		
		
		private var testing:Boolean = false;
		
		private const events:Survival1Events = new Survival1Events();
		
		private const fireIds:Array = ["backFire", "frontFire"];
		private const buttonIds:Array = [this.events.DRY_KINDLING, this.events.WET_KINDLING, this.events.LOGS, this.events.NEST, FLINT_AND_STRIKER, this.events.MITTENS];
		private const fireParts:Array = [this.events.DRY_KINDLING, this.events.WET_KINDLING, this.events.LOGS, this.events.NEST];
		private var fireArea:DisplayObjectContainer;
		
		/**
		 * Wind will basically be determined by whether windX < 0, windX > 0, or windX = 0. Any negative value
		 * means the wind is blowing left, any positive value means the wind is blowing right, and 0 means there's
		 * no wind at all.
		 */
		private var windX:int;
		
		private var hasMittens:Boolean 		= false;
		private var groundCleared:Boolean 	= false;
		private var fireBlown:Boolean		= false;
		private var numStrikes:int = 0;
		
		//Don't want to trigger the close of the popup more than once.
		private var checkedHands:Boolean = false;
		
		private var hand:Entity;
		private var snow:Entity;
		private var flintAndStriker:Entity;
		
		//Separate handling for digging the striker out of the snow.
		private var building:Boolean;
		
		public function FirePopup(container:DisplayObjectContainer = null, windX:int = 0, building:Boolean = true)
		{
			super(container);
			
			this.windX = windX;
			/*
			Building defaults to true 'cause on most occasions we'll be trying to build a fire. The only time
			this will be false is when trying to unbury the striker.
			*/
			this.building = building;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = 0.3;
			this.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			this.transitionOut = this.transitionIn.duplicateSwitch();
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/survival1/shared/firePopup/";
			this.screenAsset = "firePopup.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.addSystem(new SpatialToMouseSystem());
			this.addSystem(new BitmapCleanSystem());
			
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM)
			{
				PARTICLE_RATE_START / 2;
				PARTICLE_RATE_INCREASE / 2;
			}
			
			//These all need to happen whether you're building a fire OR digging up the striker.
			this.setupAspectRatio();
			this.setupFireArea();
			this.setupRandomizedBackground();
			this.setupGround();
			this.setupHandButton();
			this.setupCloseButton();
			
			//Building a fire.
			if(this.building)
			{
				this.setupButtonPositions();
				this.setupFlintAndStriker();
				this.setupHandbookButton();
				this.setupFirePartButtons();
				this.setupBlowFireButton();
				this.setupFlintAndStrikerButton();
				
				this.setupRestartButton();
				
				this.fireArea.removeChild(this.fireArea.getChildByName(this.events.STRIKER));
			}
			//Digging up the Striker.
			else
			{
				this.removeAssetsForDigging();
				
				var clean:BitmapClean = this.snow.get(BitmapClean);
				clean.cleaned.add(onDoneDigging);
			}
		}
		
		private function setupButtonPositions():void
		{
			if(!this.testing)
			{
				if(!this.shellApi.checkHasItem(this.events.DRY_KINDLING))
				{
					this.buttonIds.splice(this.buttonIds.indexOf(this.events.DRY_KINDLING), 1);
					this.screen.removeChild(this.screen.getChildByName(this.events.DRY_KINDLING + "Button"));
				}
				
				if(!this.shellApi.checkHasItem(this.events.WET_KINDLING))
				{
					this.buttonIds.splice(this.buttonIds.indexOf(this.events.WET_KINDLING), 1);
					this.screen.removeChild(this.screen.getChildByName(this.events.WET_KINDLING + "Button"));
				}
				
				if(!this.shellApi.checkHasItem(this.events.LOGS))
				{
					this.buttonIds.splice(this.buttonIds.indexOf(this.events.LOGS), 1);
					this.screen.removeChild(this.screen.getChildByName(this.events.LOGS + "Button"));
				}
				
				if(!this.shellApi.checkHasItem(this.events.NEST))
				{
					this.buttonIds.splice(this.buttonIds.indexOf(this.events.NEST), 1);
					this.screen.removeChild(this.screen.getChildByName(this.events.NEST + "Button"));
				}
				
				if((!this.shellApi.checkHasItem(this.events.FLINT) || !this.shellApi.checkHasItem(this.events.STRIKER)))
				{
					this.buttonIds.splice(this.buttonIds.indexOf(FLINT_AND_STRIKER), 1);
					this.screen.removeChild(this.screen.getChildByName(FLINT_AND_STRIKER + "Button"));
				}
			}
			
			/*
			Spreads out the buttons for items you actually have evenly across the bottom of the screen.
			This accounts for all screen sizes.
			*/
			var numButtons:int = this.buttonIds.length;
			var offsetX:Number = this.shellApi.viewportWidth / numButtons;
			var half:Number = offsetX / 2;
			
			for(var i:int = numButtons - 1; i >= 0; --i)
			{
				var clip:MovieClip = this.screen.getChildByName(this.buttonIds[i] + "Button");
				clip.x = offsetX * (i + 1) - half;
			}
		}
		
		private function onDoneDigging(entity:Entity):void
		{	
			//Don't need close getting called twice!
			this.getEntityById("closePopupButton").get(Interaction).lock = true;
			
			if(!this.hasMittens) return;
			
			var clip:MovieClip = this.fireArea.getChildByName(this.events.STRIKER) as MovieClip;
			
			DisplayUtils.moveToTop(clip);
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(clip, 0.5, {scaleX:2, scaleY:2, onComplete:this.close});
			
			/*
			This can work because this Signal gets dispatched JUST before the Group is destroyed, thus giving me
			access to Group functions and variables. Huzzah!
			 */
			this.removed.addOnce(getStrikerItem);
		}
		
		private function getStrikerItem(group:Group):void
		{
			this.shellApi.getItem(this.events.STRIKER, null, true);
			this.shellApi.triggerEvent(this.events.RETRIEVED_STRIKER, true);
		}
		
		private function removeAssetsForDigging():void
		{
			var container:DisplayObjectContainer = this.screen;
			container.removeChild(container.getChildByName(this.events.DRY_KINDLING + "Button"));
			container.removeChild(container.getChildByName(this.events.WET_KINDLING + "Button"));
			container.removeChild(container.getChildByName(this.events.LOGS + "Button"));
			container.removeChild(container.getChildByName(this.events.NEST + "Button"));
			container.removeChild(container.getChildByName(FLINT_AND_STRIKER + "Button"));
			container.removeChild(container.getChildByName(this.events.SURVIVAL_HANDBOOK + "Button"));
			container.removeChild(container.getChildByName(RESTART + "Button"));
			container.removeChild(container.getChildByName(FLINT_AND_STRIKER));
			container.removeChild(container.getChildByName(BLOW_FIRE + "Button"));
		}
		
		private function setupGround():void
		{
			this.snow = new Entity();
			this.addEntity(this.snow);
			
			var wrapper:BitmapWrapper;
			if(this.building) wrapper = this.convertToBitmapSprite(this.fireArea.getChildByName("fireSnow"));
			else wrapper = this.convertToBitmapSprite(DisplayObjectContainer(this.fireArea.getChildByName("fireSnow")).getChildByName("strikerSnow"));
			
			var display:Display 	= new Display( wrapper.sprite, wrapper.sprite.parent);
			this.snow.add(display);
			
			InteractionCreator.addToEntity(this.snow, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			
			var clean:BitmapClean = new BitmapClean(50, 0.9, true);
			clean.startCleaning.add(onStartCleaning);
			clean.cleaned.add(onCleaned);
			this.snow.add(clean);
		}
		
		private function setupFlintAndStriker():void
		{
			var clip:MovieClip = this.screen.getChildByName(FLINT_AND_STRIKER);
			
			this.flintAndStriker = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this, this.flintAndStriker, null, false);
			
			this.flintAndStriker.get(Display).visible = false;
			
			var timeline:Timeline = this.flintAndStriker.get(Timeline);
			timeline.handleLabel("strike", makeSparks, false);
			timeline.handleLabel("down", onFlintAndStrikerHit, false);
			
			var sparks:Entity = EmitterCreator.create(this, this.screen, new FlintSparks(), 0, 0, null, "sparks", null, false);
			
			var spatial:Spatial = sparks.get(Spatial);
			spatial.x = clip.x + 20;
			spatial.y = clip.y + 20;
		}
		
		private function makeSparks():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flint_strike_0" + Utils.randInRange(1, 3) + ".mp3");
			
			var entity:Entity = this.getEntityById("sparks");
			entity.get(Emitter).start = true;
		}
		
		private function onFlintAndStrikerHit():void
		{
			this.numStrikes++;
			if(this.numStrikes >= 3)
			{
				this.flintAndStriker.get(Display).visible = false;
				this.flintAndStriker.get(Timeline).gotoAndStop(0);
				
				this.numStrikes = 0;
				
				var hasParts:Boolean = false;
				var entity:Entity;
				var id:String;
				
				for each(id in this.fireParts)
				{
					if(this.fireArea.getChildByName(id).visible)
					{
						hasParts = true;
						entity = this.getEntityById(id + "Button");
						entity.get(Interaction).lock = true;
					}
				}
				
				entity = this.getEntityById(FLINT_AND_STRIKER + "Button");
				entity.get(Display).displayObject.getChildByName(this.events.FLINT).visible = true;
				entity.get(Display).displayObject.getChildByName(this.events.STRIKER).visible = true;
				entity.get(Interaction).lock = hasParts;
				
				if(hasParts)
				{	
					entity = this.getEntityById(this.events.MITTENS + "Button");
					entity.get(Display).displayObject.getChildByName(this.events.MITTENS).visible = true;
					entity.get(Interaction).lock = true;
					
					this.setMittenAndGround(false);
					this.setFireParticles(true);
					this.checkLitFire();
				}
			}
		}
		
		private function checkLitFire():void
		{
			if(!this.groundCleared || this.fireArea.getChildByName(this.events.WET_KINDLING).visible)
			{
				this.triggerFireStatusEventAndClose(this.events.FIRE_TOO_WET);
			}
			else if(this.windX != 0)
			{
				this.triggerFireStatusEventAndClose(this.events.FIRE_TOO_WINDY);
			}
			else if(!this.fireArea.getChildByName(this.events.NEST).visible || this.fireArea.getChildByName(this.events.DRY_KINDLING).visible || this.fireArea.getChildByName(this.events.LOGS).visible)
			{
				this.triggerFireStatusEventAndClose(this.events.FIRE_BUILT_WRONG);
			}
			else
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.showBlowFireButton));
			}
		}
		
		private function showBlowFireButton():void
		{
			var entity:Entity;
			
			entity = this.getEntityById(BLOW_FIRE + "Button");
			entity.get(Display).visible 	= true;
			entity.get(Interaction).lock 	= false;
			
			for each(var id:String in this.buttonIds)
			{
				entity = this.getEntityById(id + "Button");
				if(entity) entity.get(Display).visible = false;
			}
			
			SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, this.fireBurnTimeout));
		}
		
		private function fireBurnTimeout():void
		{
			if(this.fireBlown) return;
			this.triggerFireStatusEventAndClose(this.events.FIRE_DIED);
		}
		
		private function setFireParticles(on:Boolean):void
		{
			var id:String;
			var entity:Entity;
			var emitter:Emitter;
			
			if(on)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "fire_burst_01.mp3");
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "fire_03_L.mp3", 1, true);
				
				for each(id in this.fireIds)
				{
					entity = this.getEntityById(id);
					
					emitter = entity.get(Emitter);
					emitter.emitter.counter.resume();
					emitter.start = true;
				}
			}
			else
			{
				AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "fire_03_L.mp3");
				AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "fire_05_L.mp3");
				
				for each(id in this.fireIds)
				{
					entity = this.getEntityById(id);
					
					emitter = entity.get(Emitter);
					emitter.emitter.counter.stop();
					Steady(emitter.emitter.counter).rate = PARTICLE_RATE_START;
				}
			}
		}
		
		private function setMittenAndGround(on:Boolean):void
		{
			var entity:Entity 	= this.getEntityById(this.events.MITTENS + "Button");
			var value:String 	= entity.get(Button).value;
			entity.get(Display).displayObject.getChildByName(value).visible = !on;
			
			if(on)
			{
				this.snow.get(BitmapClean).locked 		= false;
				this.hand.get(SpatialToMouse).locked 	= false;
			}
			else
			{
				this.snow.get(BitmapClean).locked 		= true;
				this.hand.get(SpatialToMouse).locked 	= true;
				
				var spatial:Spatial = this.hand.get(Spatial);
				spatial.x = spatial.y = -100;
			}
		}
		
		private function setupAspectRatio():void
		{
			var scaleX:Number = this.shellApi.viewportWidth / 960;
			var scaleY:Number = this.shellApi.viewportHeight / 640;
			var y:Number = this.shellApi.viewportHeight - 80;
			var clip:MovieClip;
			
			clip = this.screen.getChildByName("fireArea");
			clip.x *= scaleX;
			clip.y *= scaleY;
			
			clip = this.screen.getChildByName("background");
			clip.scaleX = scaleX;
			clip.scaleY = scaleY;
			
			clip = this.screen.getChildByName(this.events.DRY_KINDLING + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(this.events.WET_KINDLING + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(this.events.LOGS + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(this.events.NEST + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(FLINT_AND_STRIKER + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(this.events.MITTENS + "Button");
			//clip.x *= scaleX;
			clip.y = y;
			if(!this.building) clip.x = this.shellApi.viewportWidth / 2;
			
			clip = this.screen.getChildByName(BLOW_FIRE + "Button");
			clip.x *= scaleX;
			clip.y = y;
			
			clip = this.screen.getChildByName(FLINT_AND_STRIKER);
			clip.x *= scaleX;
			clip.y *= scaleY;
			
			this.screen.getChildByName(RESTART + "Button").x 		*= scaleX;
			this.screen.getChildByName(CLOSE_POPUP + "Button").x 	*= scaleX;
		}
		
		private function setupHandButton():void
		{
			var clip:MovieClip = this.screen.getChildByName(this.events.MITTENS + "Button");
			var value:String;
			
			if(this.shellApi.checkHasItem(events.MITTENS) || this.testing)
			{
				value = "mittens";
				this.hasMittens = true;
				clip.removeChild(clip.getChildByName("hand"));
				DisplayObjectContainer(clip.getChildByName("background")).removeChild(DisplayObjectContainer(clip.getChildByName("background")).getChildByName("handShadow"));
				this.screen.removeChild(this.screen.getChildByName("hand"));
			}
			else
			{
				value = "hand";
				this.hasMittens = false;
				clip.removeChild(clip.getChildByName("mittens"));
				DisplayObjectContainer(clip.getChildByName("background")).removeChild(DisplayObjectContainer(clip.getChildByName("background")).getChildByName("mittenShadow"));
				this.screen.removeChild(this.screen.getChildByName("mittens"));
			}
			
			this.convertToBitmap(clip.getChildByName("background"));
			
			var display:DisplayObjectContainer = this.screen.getChildByName(value);
			display.mouseEnabled = false;
			display.mouseChildren = false;
			this.hand = EntityUtils.createSpatialEntity(this, display);
			this.hand.add(new SpatialToMouse(this.screen, null, true));
			
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onHandButtonClicked);
			entity.add(new Id(clip.name));
			entity.get(Button).value = value;
		}
		
		private function onHandButtonClicked(entity:Entity):void
		{
			var value:String = entity.get(Button).value;
			var childIcon:DisplayObject = entity.get(Display).displayObject.getChildByName(value);
			
			this.setMittenAndGround(childIcon.visible);
		}
		
		private function onStartCleaning(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ls_snow_slide_0" + Utils.randInRange(1, 2) + ".mp3", 1, false, [SoundModifier.EFFECTS]);
			
			if(this.hasMittens) return;
			if(this.checkedHands) return;
			
			this.checkedHands = true;
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, this.handTooCold));
		}
		
		private function handTooCold():void
		{
			this.shellApi.triggerEvent(this.events.FIRE_COLD_HANDS);
			this.setMittenAndGround(false);
			this.close();
		}
		
		private function onCleaned(entity:Entity):void
		{
			this.groundCleared = true;
		}
		
		private function setupBlowFireButton():void
		{
			var entity:Entity = ButtonCreator.createButtonEntity(this.screen.getChildByName(BLOW_FIRE + "Button"), this, this.onBlowFireButtonClicked);
			entity.add(new Id(BLOW_FIRE + "Button"));
			entity.get(Display).visible 	= false;
			entity.get(Interaction).lock 	= true;
		}
		
		private function onBlowFireButtonClicked(entity:Entity = null):void
		{
			var id:String;
			
			entity = this.getEntityById(BLOW_FIRE + "Button");
			entity.get(Display).visible 	= false;
			entity.get(Interaction).lock 	= true;
			
			for each(id in this.buttonIds)
			{
				entity = this.getEntityById(id + "Button");
				if(entity) entity.get(Display).visible = true;
			}
			
			this.fireBlown = true;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "fire_05_L.mp3", 1, true);
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "fire_03_L.mp3");
			
			for each(id in this.fireIds)
			{
				entity = this.getEntityById(id);
				
				var emitter:Emitter = entity.get(Emitter);
				Steady(emitter.emitter.counter).rate = PARTICLE_RATE_INCREASE;
			}
		}
		
		private function setupHandbookButton():void
		{
			var clip:MovieClip = this.screen.getChildByName(this.events.SURVIVAL_HANDBOOK + "Button");
			
			if(this.shellApi.checkHasItem(this.events.HANDBOOK_PAGES) || this.testing)
			{
				ButtonCreator.createButtonEntity(clip, this, this.onHandbookButtonClicked);
				clip.removeChild(clip.getChildByName(this.events.SURVIVAL_HANDBOOK + "Shadow"));
				this.convertToBitmap(clip.getChildByName("background"));
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		private function onHandbookButtonClicked(entity:Entity):void
		{
			var survivalGuide:HandBookPopup = new HandBookPopup(this.groupContainer);
			survivalGuide.configData("survivalHandbook.swf", "scenes/survival1/shared/survivalHandbookPopup/", 6, events.HANDBOOK_PAGE_, events.SURVIVAL_HANDBOOK);
			survivalGuide.ready.addOnce(this.hidePopup);
			survivalGuide.removed.addOnce(this.showPopup);
			
			this.addChildGroup(survivalGuide);
		}
		
		private function hidePopup(group:Group):void
		{
			this.screen.visible = false;
		}
		
		private function showPopup(group:Group):void
		{
			this.screen.visible = true;
		}
		
		private function setupFirePartButtons():void
		{
			//var parts:Array = [this.events.DRY_KINDLING, this.events.WET_KINDLING, this.events.LOGS, this.events.NEST];
			
			//-3 excludes the flint and striker and mittens
			for(var i:int = this.fireParts.length - 1; i >= 0; --i)
			{
				var part:String = this.fireParts[i];
				
				var clip:MovieClip = this.screen.getChildByName(part + "Button");
				
				if(clip)//this.shellApi.checkItem(part) || this.testing)
				{
					var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onFirePartButtonClicked);
					entity.add(new Id(clip.name));
					entity.get(Button).value = part;
					
					this.convertToBitmap(clip.getChildByName("background"));
				}
				/*else
				{
					clip.parent.removeChild(clip);
				}*/
			}
		}
		
		private function onFirePartButtonClicked(entity:Entity):void
		{
			var value:String = entity.get(Button).value;
			var childIcon:DisplayObject = entity.get(Display).displayObject.getChildByName(value);
			
			this.playFirePartSound(value);
			
			childIcon.visible = childIcon.visible ? false : true;
			
			var firePart:Bitmap = this.fireArea.getChildByName(value) as Bitmap;
			if(childIcon.visible)
			{
				firePart.visible = false;
			}
			else
			{
				firePart.visible = true;
				DisplayUtils.moveToTop(firePart);
				
				//Have to put the front fire particles in front of the fire again...
				entity = this.getEntityById("frontFire");
				DisplayUtils.moveToTop(entity.get(Display).displayObject);
			}
			
			this.checkStackedFire();
			
			this.setMittenAndGround(false);
		}
		
		private function playFirePartSound(value:String):void
		{
			switch(value)
			{
				case this.events.NEST:
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grass_rustle_01.mp3");
					break;
				
				case this.events.DRY_KINDLING:
				case this.events.WET_KINDLING:
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_impact_multiple_01.mp3");
					break;
				
				case this.events.LOGS:
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_impact_logs_01.mp3");
					break;
			}
		}
		
		private function checkStackedFire():void
		{
			if(!this.groundCleared) return;
			if(!this.fireBlown) 	return;
			
			var dryKindling:DisplayObject 	= this.fireArea.getChildByName(this.events.DRY_KINDLING);
			var wetKindling:DisplayObject	= this.fireArea.getChildByName(this.events.WET_KINDLING);
			var logs:DisplayObject 			= this.fireArea.getChildByName(this.events.LOGS);
			var nest:DisplayObject 			= this.fireArea.getChildByName(this.events.NEST);
			
			if(wetKindling.visible)
			{
				this.triggerFireStatusEventAndClose(this.events.FIRE_TOO_WET);
			}
			else
			{
				var rate:int = PARTICLE_RATE_INCREASE;
				if(dryKindling.visible) rate += PARTICLE_RATE_INCREASE;
				if(logs.visible) 		rate += PARTICLE_RATE_INCREASE;
				
				for each(var id:String in this.fireIds)
				{
					var entity:Entity = this.getEntityById(id);
					
					var emitter:Emitter = entity.get(Emitter);
					Steady(emitter.emitter.counter).rate = rate;
				}
				
				if(dryKindling.visible && logs.visible)
				{
					var nestIndex:int 			= this.fireArea.getChildIndex(nest);
					var dryKindlingIndex:int 	= this.fireArea.getChildIndex(dryKindling);
					var logsIndex:int			= this.fireArea.getChildIndex(logs);
					
					if(dryKindlingIndex > nestIndex && logsIndex > dryKindlingIndex)
					{
						//Success! Closing the popup for now.
						AudioUtils.play(this, SoundManager.MUSIC_PATH + "MiniGameWin.mp3");
						this.triggerFireStatusEventAndClose(this.events.FIRE_COMPLETED);
					}
				}
			}
		}
		
		private function triggerFireStatusEventAndClose(event:String):void
		{
			var save:Boolean = false;
			
			if(event == this.events.FIRE_COMPLETED)
			{
				save = true;
				SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, this.close));
			}
			else
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, Command.create(this.setFireParticles, false)));
				SceneUtil.addTimedEvent(this, new TimedEvent(7, 1, this.close));
			}
			
			this.shellApi.triggerEvent(event, save);
			
			for each(var id:String in this.buttonIds)
			{
				var entity:Entity = this.getEntityById(id + "Button");
				if(entity) entity.get(Interaction).lock = true;
			}
			
			this.getEntityById("restartButton").get(Interaction).lock = true;
			this.getEntityById("closePopupButton").get(Interaction).lock = true;
		}
		
		private function setupFlintAndStrikerButton():void
		{
			var clip:MovieClip = this.screen.getChildByName(FLINT_AND_STRIKER + "Button");
			
			if(clip)
			{
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onFlintAndStrikerButtonClicked);
				entity.add(new Id(clip.name));
				
				this.convertToBitmap(clip.getChildByName("background"));
			}
		}
		
		private function onFlintAndStrikerButtonClicked(entity:Entity):void
		{
			var flintIcon:DisplayObject 	= entity.get(Display).displayObject.getChildByName(this.events.FLINT);
			var strikerIcon:DisplayObject 	= entity.get(Display).displayObject.getChildByName(this.events.STRIKER);
			
			var button:Entity;
			var id:String;
			
			if(flintIcon.visible)
			{
				flintIcon.visible 	= false;
				strikerIcon.visible = false;
				
				this.flintAndStriker.get(Display).visible = true;
				this.flintAndStriker.get(Timeline).gotoAndPlay(0);
			}
			else
			{
				flintIcon.visible 	= true;
				strikerIcon.visible = true;
				
				this.numStrikes = 0;
				
				this.flintAndStriker.get(Display).visible = false;
				this.flintAndStriker.get(Timeline).gotoAndStop(0);
			}
			
			this.setMittenAndGround(false);
		}
		
		private function setupRestartButton():void
		{
			ButtonCreator.createButtonEntity(this.screen.getChildByName("restartButton"), this, this.onRestartButtonClicked);
		}
		
		private function onRestartButtonClicked(entity:Entity):void
		{
			var clip:DisplayObjectContainer;
			var id:String;
			
			//Reset fire area DisplayObjects to be invisible.
			this.fireArea.getChildByName(this.events.DRY_KINDLING).visible = false;
			this.fireArea.getChildByName(this.events.WET_KINDLING).visible = false;
			this.fireArea.getChildByName(this.events.LOGS).visible 		= false;
			this.fireArea.getChildByName(this.events.NEST).visible 		= false;
			
			//Reset all button icons to be visible again.
			clip = this.screen.getChildByName(this.events.DRY_KINDLING + "Button");
			if(clip) clip.getChildByName(this.events.DRY_KINDLING).visible = true;
			
			clip = this.screen.getChildByName(this.events.WET_KINDLING + "Button");
			if(clip) clip.getChildByName(this.events.WET_KINDLING).visible = true;
			
			clip = this.screen.getChildByName(this.events.LOGS + "Button");
			if(clip) clip.getChildByName(this.events.LOGS).visible = true;
			
			clip = this.screen.getChildByName(this.events.NEST + "Button");
			if(clip) clip.getChildByName(this.events.NEST).visible = true;
			
			clip = this.screen.getChildByName(FLINT_AND_STRIKER + "Button");
			if(clip)
			{
				clip.getChildByName(this.events.FLINT).visible = true;
				clip.getChildByName(this.events.STRIKER).visible = true;
			}
			
			clip = this.screen.getChildByName(this.events.MITTENS + "Button");
			if(clip)
			{
				if(clip.getChildByName("hand")) 	clip.getChildByName("hand").visible 	= true;
				if(clip.getChildByName("mitten")) 	clip.getChildByName("mitten").visible 	= true;
			}
			
			//Move snow-clearing hand Entity off-screen.
			this.setMittenAndGround(false);
			
			//Stop fire particle emitters immediately.
			this.setFireParticles(false);
			this.fireBlown = false;
			
			//Rset flint and striker Entity to be invisible and reset and stop its Timeline.
			this.flintAndStriker.get(Display).visible = false;
			this.flintAndStriker.get(Timeline).gotoAndStop(0);
			
			//Unlock all button interactions.
			for each(id in this.buttonIds)
			{
				//Check to see if button exists. Some buttons aren't made if you don't have the items.
				entity = this.getEntityById(id + "Button");
				if(entity) entity.get(Interaction).lock = false;
			}
			
			//Reset how many times the striker has done its animation.
			this.numStrikes = 0;
		}
		
		private function setupCloseButton():void
		{
			ButtonCreator.createButtonEntity(this.screen.getChildByName("closePopupButton"), this, this.onCloseClicked);
		}
		
		private function onCloseClicked(entity:Entity):void
		{
			this.setMittenAndGround(false);
			this.close();
		}
		
		private function setupRandomizedBackground():void
		{
			/*
			Inner and outer Rectangles can be within 960x640 because the background parts get moved, and then the
			entire background container get scaled to fit the screen.
			*/
			var background:DisplayObjectContainer = this.screen.getChildByName("background");
			
			
			var i:int;
			var clip:MovieClip;
			var point:Point;
			
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM)
			{
				for(i = 1; i <= 11; ++i)
				{
					clip = this.screen.getChildByName("frontSwap" + i);
					clip.parent.removeChild(clip);
				}
				
				for(i = 1; i <= 2; ++i)
				{
					clip = this.screen.getChildByName("frontGrass" + i);
					clip.parent.removeChild(clip);
				}
				
				for(i = 1; i <= 5; i++)
				{
					clip = background.getChildByName("backSwap" + i) as MovieClip;
					clip.parent.removeChild(clip);
				}
				
				for(i = 1; i <= 3; i++)
				{
					clip = background.getChildByName("backGrass" + i) as MovieClip;
					clip.parent.removeChild(clip);
				}
			}
			else
			{
				var scaleX:Number = this.shellApi.viewportWidth / 960;
				var scaleY:Number = this.shellApi.viewportHeight / 640;
				
				var outer:Rectangle = new Rectangle();
				outer.left 		= 0;
				outer.top 		= 140 * scaleY;
				outer.right 	= this.shellApi.viewportWidth;
				outer.bottom 	= this.shellApi.viewportHeight;
				
				var inner:Rectangle = new Rectangle();
				inner.left 		= this.fireArea.x - 200;
				inner.top 		= this.fireArea.y - 50;
				inner.right 	= this.fireArea.x + 200;
				inner.bottom 	= this.fireArea.y + 200;
				
				for(i = 1; i <= 11; i++)
				{
					clip = this.screen.getChildByName("frontSwap" + i);
					point = GeomUtils.getPointWithinRects(outer, inner);
					clip.x 			= point.x;
					clip.y 			= point.y;
					
					if(clip.y < this.fireArea.y)
					{
						clip.parent.setChildIndex(clip, clip.parent.getChildIndex(this.fireArea));
					}
					
					this.convertToBitmap(clip);
				}
				
				for(i = 1; i <= 2; i++)
				{
					clip = this.screen.getChildByName("frontGrass" + i);
					point = GeomUtils.getPointWithinRects(outer, inner);
					clip.x 			= point.x;
					clip.y 			= point.y;
					
					if(clip.y < this.fireArea.y)
					{
						clip.parent.setChildIndex(clip, clip.parent.getChildIndex(this.fireArea));
					}
					
					this.makeGrass(clip);
				}
				
				for(i = 1; i <= 5; i++)
				{
					clip = background.getChildByName("backSwap" + i) as MovieClip;
					clip.x = Utils.randNumInRange(0, 960);
					this.convertToBitmap(clip);
				}
				
				for(i = 1; i <= 3; i++)
				{
					clip = background.getChildByName("backGrass" + i) as MovieClip;
					clip.x = Utils.randNumInRange(0, 960);
					this.makeGrass(clip);
				}
			}
			
			this.convertToBitmap(background.getChildByName("snow"));
			this.convertToBitmap(background.getChildByName("sky"));
		}
		
		private function makeGrass(clip:MovieClip):void
		{
			var entity:Entity = EntityUtils.createDisplayEntity(this, clip);
			TimelineUtils.convertClip(clip, this, entity);
			
			var timeline:Timeline = entity.get(Timeline);
			if(this.windX < 0) 		timeline.gotoAndPlay("startLeft");
			else if(this.windX > 0) timeline.gotoAndPlay("startRight");
			else 					timeline.gotoAndStop(0);
		}
		
		private function setupFireArea():void
		{
			this.fireArea = this.screen.getChildByName("fireArea");
			
			this.convertToBitmap(this.fireArea.getChildByName("clearedGround"));
			
			for each(var part:String in this.fireParts)
			{
				this.convertToBitmap(this.fireArea.getChildByName(part));
				this.fireArea.getChildByName(part).visible = false;
			}
			
			this.createFireParticles();
		}
		
		private function createFireParticles():void
		{
			var height:Number = this.fireArea.y;
			
			var accelerationX:Number = 0;
			if(windX < 0) 		accelerationX = -200;
			else if(windX > 0) 	accelerationX = 200;
			
			var radii:Array = [120, 80];
			var indices:Array = [3, 7];
			
			for(var i:int = 0; i < this.fireIds.length; i++)
			{
				var entity:Entity = new Entity();
				this.addEntity(entity);
				
				entity.add(new Id(this.fireIds[i]));
				entity.add(new Spatial(20, 50));
				
				var displayObject:BitmapRenderer = new BitmapRenderer(new Rectangle(-500, -height, 1000, height + 100), false);
				
				var display:Display 	= new Display(displayObject, this.fireArea);
				display.isStatic 		= true;
				display.setIndex(indices[i])
				entity.add(display);
				
				var emitter:Emitter = new Emitter();
				emitter.emitter = new CampFire(radii[i], PARTICLE_RATE_START, accelerationX);
				emitter.stop = true;
				displayObject.addEmitter(emitter.emitter);
				entity.add(emitter);
			}
		}
	}
}