package game.scenes.hub.avatarShop
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import game.components.Emitter;
	import game.components.motion.Draggable;
	import game.components.motion.WaveMotion;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Pop;
	import game.data.character.LookData;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.systems.motion.DraggableSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.Utils;
	
	public class Colorizer extends Popup
	{
		private var _tween:Tween;
		
		private var _colorsBitmapData:BitmapData;
		private var _color:uint;
		
		private var _dummy:Entity;
		private var _changedColors:Boolean = false;
		
		private var _shaking:Boolean = false;
		private var _shower:DisplayObject;
		private var _machine:Entity;
		private var _steam:Entity;
		
		private var _selector:Entity;
		private var _slider:Entity;
		
		private var _colors:DisplayObject;
		private var _overlayWhite:DisplayObject;
		private var _overlayBlack:DisplayObject;
		private var _buttonColor:DisplayObject;
		
		public function Colorizer(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "Colorizer";
			this.groupPrefix 		= "scenes/hub/avatarShop/colorizer/";
			this.screenAsset 		= "colorizer.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{
			this._colorsBitmapData.dispose();
			this._colorsBitmapData = null;
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			this.screen.visible = false;
			
			this.addSystem(new DraggableSystem());
			this.addSystem(new SliderSystem());
			this.addSystem(new WaveMotionSystem());
			
			this._tween = this.getGroupEntityComponent(Tween);
			this._buttonColor = this.screen.content.colorizer.machine.buttonColor;
			
			this.setupAcceptAndCancel();
			this.setupMachine();
			this.setupCharacter();
			this.setupSelector();
			this.setupSlider();
			this.setupColorButtons();
			this.createColorBitmapData();
		}
		
		private function setupAcceptAndCancel():void
		{
			var content:MovieClip = this.screen.content;
			ButtonCreator.createButtonEntity(content.accept, this, this.onAccept, null, null, null, true, true);
			ButtonCreator.createButtonEntity(content.cancel, this, this.onCancel, null, null, null, true, true);
		}
		
		private function onAccept(entity:Entity):void
		{
			if(this._changedColors)
			{
				this.shellApi.triggerEvent("cant_recognize");
			}
			SkinUtils.applyLook(this.shellApi.player, SkinUtils.getLook(this._dummy));
			this.shellApi.saveLook();
			this.playClick();
			this.close();
		}
		
		private function onCancel(entity:Entity):void
		{
			this.playCancel();
			this.close();
		}
		
		private function setupMachine():void
		{
			var machine:MovieClip = this.screen.content.colorizer.machine;
			
			this._machine = EntityUtils.createSpatialEntity(this, machine);
			this._machine.add(new SpatialAddition());
			
			var wave:WaveMotion = new WaveMotion();
			wave.data.push(new WaveMotionData("x", 0, 0.7));
			this._machine.add(wave);
			
			var shower:DisplayObject 	= machine.shower;
			shower.scaleX 				= 0;
			
			var bounds:Rectangle = shower.getBounds(shower);
			bounds.inflate(40, 20);
			
			this._shower = this.createBitmapSprite(shower, 1, bounds);
			
			this._steam = EmitterCreator.create(this, machine, new MachineSteam(), 0, 0, null, null, null, false);
			Emitter(this._steam.get(Emitter)).emitter.start();
			Emitter(this._steam.get(Emitter)).emitter.counter.stop();
		}
		
		private function setupCharacter():void
		{
			var container:DisplayObjectContainer = this.screen.content.colorizer;
			
			var characterGroup:CharacterGroup = super.getGroupById("characterGroup" ) as CharacterGroup;
			if(!characterGroup)
			{
				characterGroup = super.addChildGroup(new CharacterGroup()) as CharacterGroup;
			}
			
			var lookData:LookData = SkinUtils.getLook(this.shellApi.player);
			this._dummy = characterGroup.createDummy("dummy", lookData, "left", "", container, this, this.characterLoaded, false, 1);
		}
		
		private function characterLoaded(entity:Entity):void
		{
			var spatial:Spatial = this._dummy.get(Spatial);
			spatial.x = 330;
			spatial.y = 170;
			
			//Put the player in front of his shadow.
			var display:DisplayObject = this._dummy.get(Display).displayObject;
			display.parent.setChildIndex(display, 2);
			
			var timedEvent:TimedEvent = new TimedEvent(4, 1, colorizerReady);
			timedEvent.countByUpdate = true;
			SceneUtil.addTimedEvent(this, timedEvent);
		}
		
		private function colorizerReady():void
		{
			this.screen.visible = true;
		}
		
		private function createColorBitmapData():void
		{
			if(this._colors)
			{
				this._colorsBitmapData.dispose();
			}
			
			this._colorsBitmapData = BitmapUtils.createBitmapData(this.screen.content.colorizer.machine.colorPicker.colors);
			
			this.getBitmapDataColor();
		}
		
		private function getBitmapDataColor():void
		{
			var spatial:Spatial = this._selector.get(Spatial);
			
			this._color = this._colorsBitmapData.getPixel(spatial.x, spatial.y);
			
			var colorTransform:ColorTransform 			= this._buttonColor.transform.colorTransform;
			colorTransform.color 						= this._color;
			this._buttonColor.transform.colorTransform 	= colorTransform;
		}
		
		private function setupSelector():void
		{
			this._selector = EntityUtils.createSpatialEntity(this, this.screen.content.colorizer.machine.colorPicker.selector);
			
			InteractionCreator.addToEntity(this._selector, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			ToolTipCreator.addToEntity(this._selector);
			
			this._selector.add(new MotionBounds(new Rectangle(0, 0, 200, 75)));
			
			var draggable:Draggable = new Draggable();
			draggable.dragging.add(this.onSelectorDragging);
			this._selector.add(draggable);
		}
		
		private function onSelectorDragging(entity:Entity):void
		{
			this.getBitmapDataColor();
		}
		
		private function setupSlider():void
		{
			var colorPicker:MovieClip = this.screen.content.colorizer.machine.colorPicker;
			this._overlayWhite = colorPicker.colors.overlayWhite;
			this._overlayBlack = colorPicker.colors.overlayBlack;
			
			this._slider = EntityUtils.createSpatialEntity(this, colorPicker.slider);
			
			InteractionCreator.addToEntity(this._slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			ToolTipCreator.addToEntity(this._slider);
			
			this._slider.add(new MotionBounds(new Rectangle(0, 103, 200, 0)));
			this._slider.add(new Ratio(0.5));
			this._slider.add(new Slider());
			
			var draggable:Draggable = new Draggable("x");
			draggable.dragging.add(this.onSliderDragging);
			this._slider.add(draggable);
		}
		
		private function onSliderDragging(entity:Entity):void
		{
			var decimal:Number 			= this._slider.get(Ratio).decimal;
			this._overlayWhite.alpha 	= Utils.toDecimal(decimal, 0.5, 1);
			this._overlayBlack.alpha 	= Utils.toDecimal(decimal, 0.5, 0);
			
			this.createColorBitmapData();
		}
		
		private function setupColorButtons():void
		{
			var machine:MovieClip = this.screen.content.colorizer.machine;
			ButtonCreator.createButtonEntity(machine.hairButton, this, this.changeHairColor);
			ButtonCreator.createButtonEntity(machine.skinButton, this, this.changeSkinColor);
		}
		
		private function changeHairColor(entity:Entity):void
		{
			this.animateMachine(SkinUtils.HAIR_COLOR);
		}
		
		private function changeSkinColor(entity:Entity):void
		{
			this.animateMachine(SkinUtils.SKIN_COLOR);
		}
		
		private function animateMachine(part:String):void
		{
			this._changedColors = true;
			
			if(!this._shaking)
			{
				this._shaking = true;
				
				Emitter(this._steam.get(Emitter)).emitter.counter.resume();
				
				var wave:WaveMotion 	= this._machine.get(WaveMotion);
				var data:WaveMotionData = wave.data[0];
				data.magnitude 			= 2;
				this._tween.to(data, 1, {magnitude:0});
				
				var colorTransform:ColorTransform 		= this._shower.transform.colorTransform;
				colorTransform.color 					= this._color;
				this._shower.transform.colorTransform 	= colorTransform;
				
				this._tween.to(this._shower, 0.5, {scaleX:1, onComplete:this.onShowerScaleOut, onCompleteParams:[part]});
			}
		}
		
		private function onShowerScaleOut(part:String):void
		{
			this._tween.to(this._shower, 0.25, {scaleX:0, onComplete:this.onShowerScaleIn});
			
			CharUtils.setAnim(this._dummy, Pop);
			SkinUtils.setSkinPart(this._dummy, part, this._color);
		}
		
		private function onShowerScaleIn():void
		{
			this._shaking = false;
			Emitter(this._steam.get(Emitter)).emitter.counter.stop();
		}
	}
}