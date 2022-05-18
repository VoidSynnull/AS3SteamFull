package game.scenes.time.desolation{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Transform;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Debris;
	import game.util.PerformanceUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Desolation extends PlatformerGameScene
	{
		public function Desolation()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/desolation/";

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
			_events = this.events as TimeEvents;
			
			if(super.shellApi.checkHasItem(_events.TIME_DEVICE))
			{
				placeTimeDeviceButton();
			}
			else
			{
				this.shellApi.eventTriggered.add(handleEventTrigger);
			}
			
			createBackground();
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH)
				blackParticles();
			
			createFuturePlayer();			

			var sign:Entity = ButtonCreator.createButtonEntity(this._hitContainer["sign1"], this, showSignPopup, this._hitContainer, null, null, true, true);
			ToolTipCreator.addToEntity(sign);
			
			super.ready.addOnce(onReady);		
		}
		
		private function onReady(group:Group):void
		{
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = this.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.TIME_DEVICE)
			{
				placeTimeDeviceButton();
			}
		}
		
		private function showSignPopup(button:Entity):void
		{
			var popup:TimeSign = super.addChildGroup(new TimeSign(super.overlayContainer)) as TimeSign;
			popup.id = "timeSign";
		}
		
		/**
		 * Creating a random color for the backgrounds and randomly
		 * placing the shapes side by side to create a different strucutred
		 * background and backdrop everytime. All the parts (background, backdrop, smoke) 
		 * are getting the same color transform applied to them.
		 */
		private function createBackground():void
		{
			var bkgd:Entity = getEntityById("backgroundCustom");
			var display:Display = bkgd.get(Display);
			
			var ground:Entity = getEntityById("ground");
			var groundDisplay:Display = ground.get(Display);
			
			// Create a universal color transform to be used in the background and backdrop
			var redOffset:Number = Math.random() * 160 - 100;
			var greenOffset:Number = 0;
			var blueOffset:Number = 0;
			_colorTransform = new ColorTransform(1, 1, 1, 1, redOffset, greenOffset, blueOffset, 0);
			trace(redOffset);
			
			var groundTransform:Transform = new Transform(groundDisplay.displayObject);
			groundTransform.colorTransform = _colorTransform;
			groundDisplay.displayObject = this.convertToBitmapSprite(groundDisplay.displayObject).sprite;
			
			var holder:MovieClip = MovieClip(display.displayObject.getChildByName("holder"));
			holder.mouseEnabled = false;
			var holderTransform:Transform = new Transform(holder);
			holderTransform.colorTransform = _colorTransform;
			
			_backgroundShapeX = -10;			
			shellApi.loadFile(shellApi.assetPrefix + "scenes/time/desolation/backgroundShape.swf", Command.create(shapeLoaded, holder));
			
			var backdrop:Entity = getEntityById("backdropCustom");
			var backdropDisplay:Display = backdrop.get(Display);
			
			var bdVector:MovieClip = MovieClip(backdropDisplay.displayObject.getChildByName("bdVector"));
			bdVector.mouseEnabled = false;		
			
			_brackdropShapeX = -10;
			shellApi.loadFile(shellApi.assetPrefix + "scenes/time/desolation/backdropShape.swf", Command.create(backdropShapeLoaded, bdVector));
		}
		
		private function shapeLoaded(shape:MovieClip, holder:MovieClip):void
		{
			shape.gotoAndStop(Math.ceil(Math.random() * shape.totalFrames));
			holder.addChildAt(shape, 0);
			
			var sprite:Sprite = createBitmapSprite( shape );		
			
			sprite.x = _backgroundShapeX;
			sprite.y = 410 - (Math.random() * 100 - 50);
			sprite.rotation = -10 + 20 * Math.random(); 
			sprite.scaleX = sprite.scaleY = .5 + (1 - .5) * Math.random();
			_backgroundShapeX += sprite.width/2 - 100;
			
			if(holder.width < 2600)
			{	
				shapeLoaded( shape, holder );
			}
			else
			{
				finishBackground(holder);
			}
		}
		
		private function backdropShapeLoaded(shape:MovieClip, bdVector:MovieClip):void
		{
			shape.gotoAndStop(Math.ceil(Math.random() * shape.totalFrames));
			bdVector.addChild(shape);
			
			var sprite:Sprite = createBitmapSprite( shape );			
				
			sprite.x = _brackdropShapeX;
			sprite.y = 400 - (Math.random() * 150 + 50);
			sprite.rotation = -10 + 20 * Math.random();
			sprite.scaleX = sprite.scaleY = Math.random() * .4 + .4;
			_brackdropShapeX += sprite.width/2 - 100;
			
			if(bdVector.width < 2600)
			{
				backdropShapeLoaded( shape, bdVector );
			}
			else
			{
				var backdrop:Entity = getEntityById("backdropCustom");
				var backdropDisplay:Display = backdrop.get(Display);
				var transform:Transform = new Transform(bdVector);
				transform.colorTransform = _colorTransform;
				
				backdropDisplay.displayObject = this.convertToBitmapSprite(backdropDisplay.displayObject).sprite;
				super.loaded();
			}
		}
		
		private function finishBackground(holder:MovieClip):void
		{
			var bkgd:Entity = getEntityById("backgroundCustom");
			var display:Display = bkgd.get(Display);
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				display.displayObject = this.convertToBitmapSprite(display.displayObject).sprite;
			}
			else
			{
				// Create the smoke Emitter that is in the background
				var smokeEmitter:Emitter2D = new Emitter2D();
				smokeEmitter.counter = new Random(2,3);
				smokeEmitter.addInitializer(new ImageClass(Blob, [Math.random() * 7 + 6, 0x8F6841], true));
				smokeEmitter.addInitializer(new Position(new DiscZone(null, 5)));
				smokeEmitter.addInitializer(new Velocity(new LineZone(new Point(20, -80), new Point(30, -100))));
				smokeEmitter.addInitializer(new Lifetime(7, 7));
				smokeEmitter.addAction(new ScaleImage(1, 2.5));
				smokeEmitter.addAction(new Age(Quadratic.easeIn));
				smokeEmitter.addAction(new Move());
				smokeEmitter.addAction(new Accelerate(10));
				EmitterCreator.create(this, holder, smokeEmitter, 1000, 450);	
			}
		}
		
		private function createFuturePlayer():void
		{
			var playerLook:LookData = SkinUtils.getLook(this.player, false);			
			var futurePlayer:Entity = this.getEntityById("char1");
			
			if(playerLook.getAspect(SkinUtils.EYES) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.EYES, playerLook.getAspect(SkinUtils.EYES).value);
			if(playerLook.getAspect(SkinUtils.EYE_STATE) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.EYE_STATE, playerLook.getAspect(SkinUtils.EYE_STATE).value);
			if(playerLook.getAspect(SkinUtils.GENDER) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.GENDER, playerLook.getAspect(SkinUtils.GENDER).value);
			if(playerLook.getAspect(SkinUtils.HAIR) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.HAIR, playerLook.getAspect(SkinUtils.HAIR).value);
			if(playerLook.getAspect(SkinUtils.OVERSHIRT) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.OVERSHIRT, playerLook.getAspect(SkinUtils.OVERSHIRT).value);
			if(playerLook.getAspect(SkinUtils.PANTS) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.PANTS, playerLook.getAspect(SkinUtils.PANTS).value);
			if(playerLook.getAspect(SkinUtils.SHIRT) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.SHIRT, playerLook.getAspect(SkinUtils.SHIRT).value);
			if(playerLook.getAspect(SkinUtils.SKIN_COLOR) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.SKIN_COLOR, playerLook.getAspect(SkinUtils.SKIN_COLOR).value);	
		}
		
		/**
		 * Black particles flying across the screen
		 * Using the Flint particle system
		 */
		private function blackParticles():void
		{
			var debris:Debris = new Debris();
			debris.init(new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight));
			EmitterCreator.createSceneWide(this, debris);
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		
		private var timeButton:Entity;
		private var _events:TimeEvents;
		private var _colorTransform:ColorTransform;
		
		private var _backgroundShapeX:Number = 0;
		private var _brackdropShapeX:Number = 0;
	}
}