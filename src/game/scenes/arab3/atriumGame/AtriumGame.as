package game.scenes.arab3.atriumGame
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.ShakeMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.CameraGroup;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.scenes.arab3.Arab3Events;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.atrium.Atrium;
	import game.scenes.arab3.atriumGame.hidingSpot.HidingSpot;
	import game.scenes.arab3.atriumGame.hidingSpot.HidingSpotSystem;
	import game.scenes.arab3.atriumGame.searchTimer.SearchTimer;
	import game.scenes.arab3.atriumGame.searchTimer.SearchTimerSystem;
	import game.scenes.arab3.shared.SmokePuffGroup;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class AtriumGame extends Arab3Scene
	{
		private var _smokePuffGroup:SmokePuffGroup;
		private var _bombTimer:Number = 60;
		private var _bombThrown:Boolean = false;
		
		private var _round:uint = 1;
		private var _hidingSpots:Array = [];
		
		public function AtriumGame()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/atriumGame/";
			super.init( container );
		}
		
		override public function smokeReady():void
		{
			super.smokeReady();
			
			this.addSystem(new HidingSpotSystem());
			this.addSystem(new SearchTimerSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new ShakeMotionSystem());
			
			this.removeEntity(this.player);
			
			this.shellApi.defaultCursor = ToolTipType.TARGET;
			
			this.setupGenie();
			this.setupGenieClones();
			this.setupFlash();
			this.setupBomb();
			this.setupBombTimer();
			this.setupDusts();
			this.setupSpots();
			this.setupDifferences();
			this.setupSmokePuffGroup();
			this.setupCamera();
			this.setupArrows();
		}
		
		private function setupSmokePuffGroup():void
		{
			this._smokePuffGroup = this.addChildGroup(new SmokePuffGroup()) as SmokePuffGroup;
			this._smokePuffGroup.initJinnSmoke(this, this._hitContainer);
		}
		
		private function setupBombTimer():void
		{
			var clip:MovieClip = this._hitContainer["bombCounter"];
			clip.x = this.shellApi.viewportWidth - 50;
			clip.y = this.shellApi.viewportHeight - 50;
			
			var format:TextFormat 	= new TextFormat();
			format.font 			= "CreativeBlock BB";
			format.size 			= 80;
			format.color 			= 0xFFFFFF;
			
			var textField:TextField 	= new TextField();
			textField.name 				= "bombCount";
			textField.setTextFormat(format);
			textField.defaultTextFormat = format;
			textField.mouseEnabled 		= false;
			textField.autoSize 			= TextFieldAutoSize.CENTER;
			textField.embedFonts		= true;
			textField.antiAliasType 	= AntiAliasType.NORMAL;
			textField.text 				= String(this._bombTimer);
			textField.x 				= -textField.width * 0.5;
			textField.y					= -textField.height * 0.5;
			clip.addChild(textField);
			
			var timerShake:Entity = EntityUtils.createSpatialEntity(this, clip);
			timerShake.add(new Id("timerShake"));
			timerShake.add(new SpatialAddition());
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-6, -6, 6, 6));
			shake.active = false;
			shake.speed = 0.05;
			timerShake.add(shake);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, textField);
			entity.add(new Id("bombTimer"));
			var searchTimer:SearchTimer = new SearchTimer();
			searchTimer.finished.add(this.timerFinished);
			entity.add(searchTimer);
			
			this.overlayContainer.addChildAt(clip, 0);
		}
		
		private function setupGenie():void
		{
			var genie:Entity = this.getEntityById("genie");
			genie.add(new Tween());
			genie.remove(Sleep);
			
			var display:Display = genie.get(Display);
			display.displayObject.mouseEnabled = false;
			display.displayObject.mouseChildren = false;
			DisplayUtils.moveToTop(display.displayObject);
			
			genie.remove(Interaction);
			genie.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(genie);
			
			this.addGenieWaveMotion(genie);
			
			var dialog:Dialog = genie.get(Dialog);
			dialog.faceSpeaker = false;
			dialog.sayById("tricks");
			dialog.complete.addOnce(this.startPlaying);
		}
		
		private function startPlaying(data:DialogData):void
		{
			this.roundEnd(-1, false);
		}
		
		private function setupGenieClones():void
		{
			for(var index:uint = 1; index < 4; ++index)
			{
				var clone:Entity = this.getEntityById("clone" + index);
				Display(clone.get(Display)).alpha = 0;
				
				clone.add(new Tween());
				clone.remove(Sleep);
				
				var display:Display = clone.get(Display);
				display.displayObject.mouseEnabled = false;
				display.displayObject.mouseChildren = false;
				
				clone.remove(Interaction);
				clone.remove(SceneInteraction);
				ToolTipCreator.removeFromEntity(clone);
				
				clone.add(new SpatialAddition());
				
				var radians:Number = ((Math.PI * 2) / 3) * (index - 1);
				
				var wave:WaveMotion = new WaveMotion();
				wave.add(new WaveMotionData("x", 100, 1, "cos", radians, true));
				wave.add(new WaveMotionData("y", 100, 1, "sin", radians, true));
				clone.add(wave);
			}
		}
		
		private function setupFlash():void
		{
			var shape:Shape = this.overlayContainer.addChildAt(new Shape(), 0) as Shape;
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.drawRect(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight);
			shape.graphics.endFill();
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, shape);
			Display(entity.get(Display)).alpha = 0;
			entity.add(new Id("flash"));
			
			entity.add(new Tween());
		}
		
		private function flashIn(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "event_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var flash:Entity = this.getEntityById("flash");
			Tween(flash.get(Tween)).to(flash.get(Display), 0.25, {alpha:1, onComplete:flashOut});
		}
		
		private function flashOut():void
		{
			var flash:Entity = this.getEntityById("flash");
			Tween(flash.get(Tween)).to(flash.get(Display), 0.5, {delay:0.8, alpha:0});
			
			var genie:Entity = this.getEntityById("genie");
			CharUtils.setAnim(genie, Stand);
			Display(genie.get(Display)).alpha = 0;
			
			this.putGenieOffscreen();
			
			this._smokePuffGroup.stopSpellCasting(genie);
			
			for(var index:uint = 1; index < 4; ++index)
			{
				var clone:Entity = this.getEntityById("clone" + index);
				clone.sleeping = true;
				Display(clone.get(Display)).alpha = 0;
				this._smokePuffGroup.stopSpellCasting(clone);
			}
			
			SceneUtil.lockInput(this, false);
			
			var bombTimer:Entity = this.getEntityById("bombTimer");
			var searchTimer:SearchTimer = bombTimer.get(SearchTimer);
			searchTimer.remainingTime = this._bombTimer;
			searchTimer.running = true;
			
			this.changeHidingSpots();
		}
		
		private function changeHidingSpots():void
		{
			var entity:Entity;
			var index:int;
			
			for(index = 1; index <= 17; ++index)
			{
				entity = this.getEntityById("dust" + index);
				Tween(entity.get(Tween)).to(entity.get(Display), 0.5, {alpha:0});
			}
			
			for(index = this._hidingSpots.length - 1; index > -1; --index)
			{
				entity = this.getEntityById("difference" + this._hidingSpots[index]);
				entity.remove(HidingSpot);
			}
			
			this._hidingSpots.length = 0;
			
			for(index = 0; index < 4; ++index)
			{
				do
				{
					var spotIndex:uint = Utils.randInRange(1, 17);
				}
				while(this._hidingSpots.indexOf(spotIndex) != -1);
				
				this._hidingSpots.push(spotIndex);
			}
			
			for(index = this._hidingSpots.length - 1; index > -1; --index)
			{
				entity = this.getEntityById("difference" + this._hidingSpots[index]);
				entity.add(new HidingSpot());
			}
		}
		
		private function setupBomb():void
		{
			var bomb:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["bomb"]);
			bomb.add(new Tween());
			bomb.add(new Id("bomb"));
		}
		
		private function setupDusts():void
		{
			for(var index:uint = 1; this._hitContainer.getChildByName("dust" + index); ++index)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["dust" + index]);
				entity.add(new Id("dust" + index));
				entity.add(new Tween());
				Display(entity.get(Display)).alpha = 0;
			}
		}
		
		private function setupSpots():void
		{
			for(var index:uint = 1; this._hitContainer.getChildByName("spot" + index); ++index)
			{
				var clip:MovieClip = this._hitContainer["spot" + index];
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
				entity.add(new Id("spot" + index));
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
				interaction.click.add(this.onSpotClicked);
			}
		}
		
		private function setupDifferences():void
		{
			for(var index:uint = 1; this._hitContainer.getChildByName("difference" + index); ++index)
			{
				var clip:MovieClip = this._hitContainer["difference" + index];
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertClip(clip, this, entity, null, false);
			}
		}
		
		private function onSpotClicked(entity:Entity):void
		{
			if(this._bombThrown) return;
			
			var spotIndex:int = int(Id(entity.get(Id)).id.slice(4));
			
			var dust:Entity = this.getEntityById("dust" + spotIndex);
			if(Display(dust.get(Display)).alpha == 1) return;
			
			this._bombThrown = true;
			
			var display:DisplayObject = Display(entity.get(Display)).displayObject;
			var bounds:Rectangle = display.getBounds(display.parent);
			
			this.throwBomb(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2, spotIndex);
		}
		
		private function throwBomb(targetX:Number, targetY:Number, spotIndex:int):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "object_toss_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var x:Number = this.shellApi.viewportWidth / 2;
			var y:Number = this.shellApi.viewportHeight - 100;
			
			var point:Point = DisplayUtils.localToLocalPoint(new Point(x, y), this.overlayContainer, this._hitContainer);
			
			var bomb:Entity = this.getEntityById("bomb");
			
			Display(bomb.get(Display)).visible = true;
			
			var bombSpatial:Spatial = bomb.get(Spatial);
			bombSpatial.scaleX = 1;
			bombSpatial.scaleY = 1;
			bombSpatial.rotation = Utils.randNumInRange(0, 360);
			bombSpatial.x = point.x;
			bombSpatial.y = point.y;
			
			var tween:Tween = bomb.get(Tween);
			tween.to(bombSpatial, 0.8, {y:targetY, ease:Back.easeOut, easeParams:[2]});
			tween.to(bombSpatial, 0.8, {x:targetX, rotation:bombSpatial.rotation + Utils.randNumInRange(-180, 180), scaleX:0.2, scaleY:0.2, ease:Linear.easeNone, onComplete:throwFinished, onCompleteParams:[spotIndex]});
			
			SceneUtil.lockInput(this, true);
		}
		
		private function throwFinished(spotIndex:int):void
		{
			this._bombThrown = false;
			
			SceneUtil.lockInput(this, false);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "poof_02.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var dust:Entity = this.getEntityById("dust" + spotIndex);
			Tween(dust.get(Tween)).to(dust.get(Display), 0.5, {alpha:1});
			
			var difference:Entity = this.getEntityById("difference" + spotIndex);
			difference.remove(HidingSpot);
			
			var spot:Entity = this.getEntityById("spot" + spotIndex);
			
			var smoke:Entity = this._smokePuffGroup.poofAt(spot, 0.25);
			var smokeParticles:SmokeParticles = Emitter( smoke.get( Emitter )).emitter as SmokeParticles;
			smokeParticles.endParticle.addOnce(Command.create(this._smokePuffGroup.handleSmoke, smoke, smoke.get(Id).id));
			
			var bomb:Entity = this.getEntityById("bomb");
			
			Display(bomb.get(Display)).visible = false;
			
			var bombSpatial:Spatial = bomb.get(Spatial);
			bombSpatial.scaleX = 2;
			bombSpatial.scaleY = 2;
			bombSpatial.x = -100;
			bombSpatial.y = -100;
			
			var index:int = this._hidingSpots.indexOf(spotIndex);
			if(index != -1)
			{
				this.playGenieFoundSound();
				this._hidingSpots.splice(index, 1);
				
				if(this._hidingSpots.length == 0)
				{
					++this._round;
					this.roundEnd(spotIndex, this._round == 5);
				}
				else
				{
					var genie:Entity = this.getEntityById("genie");
					var genieSpatial:Spatial = genie.get(Spatial);
					var genieDisplay:Display = genie.get(Display);
					var genieTween:Tween = genie.get(Tween);
					
					var spotSpatial:Spatial = spot.get(Spatial);
					
					genieSpatial.x = spotSpatial.x;
					genieSpatial.y = spotSpatial.y;
					
					genieTween.to(genieSpatial, 1, {y:genieSpatial.y - 100});
					genieTween.to(genieDisplay, 0.5, {alpha:1});
					genieTween.to(genieDisplay, 0.5, {alpha:0, delay:0.5, onComplete:putGenieOffscreen});
					
					CharUtils.setAnim(genie, Grief);
				}
			}
			else
			{
				var bombTimer:Entity = this.getEntityById("bombTimer");
				var searchTimer:SearchTimer = bombTimer.get(SearchTimer);
				searchTimer.remainingTime -= 5;
				
				var number:int = GeomUtils.randomInt( 1, 3 );
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "monsters_" + number + ".mp3", 1, false, [ SoundModifier.EFFECTS]);
				this.startBombTimerShake();
			}
		}
		
		private function playGenieFoundSound():void
		{
			var letters:Array = ["d", "c", "b", "a"];
			var letter:String = letters[this._hidingSpots.length - 1];
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_01" + letter + ".mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function putGenieOffscreen(...args):void
		{
			var genie:Entity = this.getEntityById("genie");
			
			var spatial:Spatial = genie.get(Spatial);
			spatial.x = spatial.y = -100;
		}
		
		private function startBombTimerShake():void
		{
			var timerShake:Entity = this.getEntityById("timerShake");
			ShakeMotion(timerShake.get(ShakeMotion)).active = true;
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, stopBombTimerShake));
		}
		
		private function stopBombTimerShake():void
		{
			var timerShake:Entity = this.getEntityById("timerShake");
			ShakeMotion(timerShake.get(ShakeMotion)).active = false;
			
			var spatialAddition:SpatialAddition = timerShake.get(SpatialAddition);
			spatialAddition.x = spatialAddition.y = 0;
		}
		
		private function timerFinished(entity:Entity):void
		{
			this.startBombTimerShake();
			this.roundEnd(-1, false);
		}
		
		private function roundEnd(spotIndex:int, gameWin:Boolean):void
		{
			SceneUtil.lockInput(this, true);
			
			//this.cameraPanOff(null);
			
			var genie:Entity = this.getEntityById("genie");
			var genieSpatial:Spatial = genie.get(Spatial);
			var genieTween:Tween = genie.get(Tween);
			
			if(spotIndex != -1)
			{
				var difference:Entity = this.getEntityById("spot" + spotIndex);
				var differenceSpatial:Spatial = difference.get(Spatial);
				
				genieSpatial.x = differenceSpatial.x;
				genieSpatial.y = differenceSpatial.y;
			}
			else
			{
				genieSpatial.x = 712;
				genieSpatial.y = 460;
			}
			
			genieTween.to(genie.get(Display), 1, {alpha:1});
			genieTween.to(genieSpatial, 2, {x:712, y:460, onComplete:genieAnimation, onCompleteParams:[spotIndex, gameWin]});
			
			CharUtils.setDirection(genie, genieSpatial.x < 712);
			
			var bombTimer:Entity = this.getEntityById("bombTimer");
			var searchTimer:SearchTimer = bombTimer.get(SearchTimer);
			searchTimer.running = false;
		}
		
		private function genieAnimation(spotIndex:int, win:Boolean):void
		{
			var genie:Entity = this.getEntityById("genie");
			
			if(win)
			{
				CharUtils.setAnim(genie, Stomp);
				
				var dialog:Dialog = genie.get(Dialog);
				dialog.sayById("enough");
				
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, flyOffAndLoadAtrium));
			}
			else
			{
				CharUtils.setAnim(genie, spotIndex == -1 ? Laugh : Stomp);
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, pickedSpots));
			}
		}
		
		private function pickedSpots():void
		{
			this._smokePuffGroup.startSpellCasting(this.getEntityById("genie"));
			
			var genie:Entity = this.getEntityById("genie");
			var genieSpatial:Spatial = genie.get(Spatial);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "event_06.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			for(var index:uint = 1; index < 4; ++index)
			{
				var clone:Entity = this.getEntityById("clone" + index);
				var cloneSpatial:Spatial = clone.get(Spatial);
				cloneSpatial.x = genieSpatial.x;
				cloneSpatial.y = genieSpatial.y;
				
				CharUtils.setDirection(clone, genieSpatial.scaleX < 0);
				
				var radians:Number = (Math.PI * 2/3) * (index - 1);
				//var x:Number = Math.cos(radians) * 100;
				//var y:Number = Math.sin(radians) * 100;
				
				var tween:Tween = clone.get(Tween);
				tween.to(clone.get(Display), 1, {alpha:1});
				
				var wave:WaveMotion = clone.get(WaveMotion);
				var data:WaveMotionData;
				
				//var radians:Number = ((Math.PI * 2) / 3) * (index - 1);
				
				
				data = wave.dataForProperty("x");
				data.magnitude = 1;
				data.radians = radians;
				tween.to(data, 1, {magnitude:100});
				data = wave.dataForProperty("y");
				data.magnitude = 1;
				data.radians = radians;
				tween.to(data, 1, {magnitude:100});
				
				this._smokePuffGroup.startSpellCasting(clone);
			}
			
			var dialog:Dialog = genie.get(Dialog);
			dialog.sayById("hide" + Utils.randInRange(1, 4));
			dialog.complete.addOnce(this.flashIn);
		}
		
		private function flyOffAndLoadAtrium():void
		{
			this.shellApi.completeEvent(Arab3Events(this.events).SPOT_THE_DIFFERENCE_COMPLETE);
			
			var genie:Entity = this.getEntityById("genie");
			CharUtils.setDirection(genie, false);
			
			Tween(genie.get(Tween)).to(genie.get(Spatial), 2.5, {x:-200, onComplete:this.loadAtrium});
		}
		
		private function loadAtrium():void
		{
			this.shellApi.loadScene(Atrium, 1690, 1240, "left");
		}
		
		private function setupCamera():void
		{
			SceneUtil.setCameraPoint(this, 1435 / 2, 1210 / 2);
			
			var width:Number = 1435 / this.shellApi.viewportWidth;
			var height:Number = 1210 / this.shellApi.viewportHeight;
			
			this.shellApi.camera.camera.scaleTarget /= width;
			this.shellApi.camera.scale = this.shellApi.camera.camera.scaleTarget;
			
			var cameraGroup:CameraGroup = this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			cameraGroup.target.y = 634 - (this.shellApi.viewportHeight / 2) / this.shellApi.camera.scale;
		}
		
		private function setupArrows():void
		{
			var arrow:Entity;
			var wave:WaveMotion;
			
			arrow = ButtonCreator.createButtonEntity(this._hitContainer["arrowDown"], this, onArrowClick, null, null, null, false, true);
			arrow.add(new SpatialAddition());
			wave = new WaveMotion();
			wave.add(new WaveMotionData("y", 5, 2, "sin", 0, true));
			arrow.add(wave);
			
			arrow = ButtonCreator.createButtonEntity(this._hitContainer["arrowUp"], this, onArrowClick, null, null, null, false, true);
			arrow.add(new SpatialAddition());
			wave = new WaveMotion();
			wave.add(new WaveMotionData("y", 5, 2, "sin", Math.PI, true));
			arrow.add(wave);
		}
		
		private function onArrowClick(entity:Entity):void
		{
			var offsetY:Number = (this.shellApi.viewportHeight / 2) / this.shellApi.camera.scale;
			var cameraGroup:CameraGroup = this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			if (cameraGroup)
			{
				if(cameraGroup.target.y > 634)
				{
					cameraGroup.target.y = 634 - offsetY;
				}
				else
				{
					cameraGroup.target.y = 634 + offsetY;
				}
			}
		}
	}
}