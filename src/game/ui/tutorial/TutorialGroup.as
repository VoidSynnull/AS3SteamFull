package game.ui.tutorial
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.render.Shadow;
	import game.components.ui.Button;
	import game.components.ui.Gesture;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.text.TextStyleData;
	import game.data.tutorials.ImageData;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.GestureData;
	import game.managers.TextManager;
	import game.particles.emitter.Ripple;
	import game.systems.render.ShadowSystem;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.GestureUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	public class TutorialGroup extends DisplayGroup
	{
		public var gesture:Entity;
		
		public function TutorialGroup(container:DisplayObjectContainer, stepDatas:Vector.<StepData> = null)
		{
			_container = container;
			this._stepDatas = stepDatas;
			complete = new Signal(DisplayGroup);	
			
			this.id = GROUP_ID;
		}
		
		public function createGesture(asset:* = null, handler:Function = null):void
		{
			gesture = GestureUtils.createGesture(asset, this, _container.parent,Command.create(gestureCreated, handler));
		}
		
		private function gestureCreated(entity:Entity, handler:Function=null):void
		{
			var gest:Gesture = entity.get(Gesture);
			
			gest.up.spatialData.rotation = 5;
			gest.up.spatialData.x = 50;
			gest.up.spatialData.y = -25;
			
			gest.up.spatialData.positionSpatial(gest.animation.get(Spatial));
			
			gest.down.spatialData.rotation = -20;
			gest.down.spatialData.scaleY = .85;
			gest.down.spatialData.x = 0;
			gest.down.spatialData.y = 0;
			
			addSystem(new ShadowSystem());
			
			var shadow:Shadow = new Shadow();
			shadow.offSetX = -30;
			shadow.offSetY = 30;
			shadow.minAlpha = .1;
			shadow.maxAlpha = .9;
			shadow.scaleGrowth = .5;
			gest.animation.add(shadow);
			
			var ripple:Ripple = new Ripple();
			ripple.init(2, .66, 16,8, 2,0xFFFFFF,false);
			
			gest.ripple = EmitterCreator.create(this, EntityUtils.getDisplayObject(entity), ripple, 0,0, gest.animation, "ripple",null, false);
			
			if(handler)
				handler();
		}
		
		public function start():void
		{
			this.parent.pause(false);
			
			var currentStep:StepData = _stepDatas.shift();
			_overlay = new Sprite();
			_container.addChild(_overlay);
			
			SceneUtil.getTimer(this); // makes timer entity for us
			getEntityById(SceneUtil.TIMER_ID).ignoreGroupPause = true;
			
			drawStep(currentStep);
		}
		
		public function addStep(step:StepData):void
		{
			if(_stepDatas == null)
				_stepDatas = new Vector.<StepData>();
			_stepDatas.push(step);	
		}
		
		private function drawStep(step:StepData):void
		{
			SceneUtil.lockInput(this, false, false);
			_currentTextfields = new Array();
			_currentImages = new Array();
			
			_overlay.graphics.clear();
			_overlay.graphics.beginFill(step.color, step.alpha);
			_overlay.graphics.drawRect(-OFFSET, -OFFSET, shellApi.viewportWidth + OFFSET*2, shellApi.viewportHeight + OFFSET*2);
			
			if(step.shapeData)
			{
				for each(var shapeData:ShapeData in step.shapeData)
				{
					if(shapeData.shapeType == ShapeData.CIRCLE)
					{
						drawCircle(shapeData, step);
					}
					else if(shapeData.shapeType == ShapeData.RECTANGLE)
					{
						drawRectangle(shapeData, step);
					}
					else if(shapeData.shapeType == ShapeData.ELLIPSE)
					{
						drawEllipse(shapeData, step);
					}
					else if(shapeData.shapeType == ShapeData.CLOSE)
					{
						ButtonCreator.loadCloseButton(this, _container, closeButtonClicked, DisplayPositions.RIGHT_CENTER, 50, 50, true, Command.create(closeButtonLoaded, shapeData));
					}
					
					// add interaction to one specified if it exists
					if(shapeData.interaction)
						shapeData.interaction.click.addOnce(Command.create(shapeClicked, step, shapeData));
					else if(shapeData.signal)
						shapeData.signal.addOnce(Command.create(shapeClicked, step, shapeData));
				}
			}
			
			_overlay.graphics.endFill();
			if(PlatformUtils.isDesktop && step.useBlur)
				_overlay.filters = [new BlurFilter(BLUR, BLUR)];
			
			if(step.imageData)
			{
				for each(var image:ImageData in step.imageData)
				{
					_container.addChild(image.display);
					image.display.x = image.xLoc;
					image.display.y = image.yLoc;
					
					_currentImages.push(image.display);
				}
			}
			
			if(step.textData)
			{
				for each(var text:TextData in step.textData)
				{
					var textfield:TextField = new TextField();
					textfield.x = text.location.x;
					textfield.y = text.location.y;
					textfield.width = text.width;
					textfield.autoSize = "center";
					textfield.embedFonts = true;
					textfield.wordWrap = true;
					textfield.antiAliasType = AntiAliasType.NORMAL;
					textfield.mouseEnabled = false;
					textfield.htmlText = text.text;
					var styleData:TextStyleData = (shellApi.getManager(TextManager) as TextManager).getStyleData(TextStyleData.UI, text.styleId);
					TextUtils.applyStyle(styleData, textfield);
					
					_container.addChild(textfield);
					_currentTextfields.push(textfield);
				}
			}
			if(step.gestureData)
			{
				for (var i:int = 0; i < step.gestureData.length; ++i)
				{
					var gestureData:GestureData = step.gestureData[i];
					if(i < step.gestureData.length - 1 && gestureData.onComplete == null)
						gestureData.onComplete = step.gestureData[i+1];
				}
				GestureUtils.performGesture(gesture, gestureData);
			}
		}
		
		private function shapeClicked(...args):void
		{
			var step:StepData = args[args.length - 2];
			var shapeData:ShapeData = args[args.length-1];
			
			clearScreen();
			
			if(shapeData.removeLink)
			{
				var removeStep:StepData = getStepById(shapeData.removeLink);
				if(removeStep)
					_stepDatas.splice(_stepDatas.indexOf(removeStep), 1);
			}
			
			if(shapeData.handler)
				shapeData.handler();
			
			if(step.delay > 0)
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(step.delay, 1, Command.create(delayDone, shapeData.clickLink)));
				SceneUtil.lockInput(this);
			}
			else
			{
				delayDone(shapeData.clickLink);
			}				
		}
		
		private function clearScreen():void
		{
			_overlay.graphics.clear();
			for each(var tf:TextField in _currentTextfields)
			{
				_container.removeChild(tf);
			}
			
			for each(var img:DisplayObject in _currentImages)
			{
				_container.removeChild(img);
			}
			
			if(_currentCloses)
			{
				for each(var closeButton:Entity in _currentCloses)
				{
					this.removeEntity(closeButton);
				}
			}
		}
		
		private function closeButtonLoaded(closeButton:Entity, shapeData:ShapeData):void
		{
			if(_currentCloses == null)
			{
				_currentCloses = new Array();				
			}
			
			_currentCloses.push(closeButton);
			closeButton.get(Display).isStatic = false;
			EntityUtils.position(closeButton, shapeData.location.x, shapeData.location.y - shapeData.height*1.5);
		}
		
		private function closeButtonClicked(...args):void
		{
			clearScreen();
			onComplete();
		}
		
		private function getStepById(id:String):StepData
		{
			for each(var step:StepData in _stepDatas)
			{
				if(step.id == id)
				{
					return step;
				}
			}
			return null;
		}
		
		private function delayDone(step:String = null):void
		{
			var nextStep:StepData;
			
			if(step)
			{
				nextStep = getStepById(step);
				if(nextStep)
					_stepDatas.splice(_stepDatas.indexOf(nextStep), 1);
			}
			else if(_stepDatas.length > 0)
			{
				nextStep = _stepDatas.shift();	
			}
			
			if(nextStep)
				drawStep(nextStep)
			else
				onComplete();
		}
		
		private function drawRectangle(shapeData:ShapeData, step:StepData):void
		{
			_overlay.graphics.drawRect(shapeData.location.x, shapeData.location.y, shapeData.width, shapeData.height);
			
			if(!shapeData.interaction && !shapeData.signal)
			{
				var clickClip:Sprite = new Sprite();
				clickClip.graphics.beginFill(0xFFFFFF, .01);
				clickClip.graphics.drawRect(shapeData.location.x, shapeData.location.y, shapeData.width, shapeData.height);
				clickClip.graphics.endFill();
				_overlay.addChild(clickClip);
				
				var clickEntity:Entity = EntityUtils.createSpatialEntity(this, clickClip);
				clickEntity.ignoreGroupPause = true;
				var interaction:Interaction = InteractionCreator.addToEntity(clickEntity, [InteractionCreator.CLICK]);
				interaction.click.addOnce(Command.create(shapeClicked, step, shapeData));
				ToolTipCreator.addToEntity(clickEntity);
			}
		}
		
		private function drawCircle(shapeData:ShapeData, step:StepData):void
		{
			_overlay.graphics.drawCircle(shapeData.location.x, shapeData.location.y, shapeData.width);
			
			if(!shapeData.interaction && !shapeData.signal)
			{
				var clickClip:Sprite = new Sprite();
				clickClip.graphics.beginFill(0xFFFFFF, .01);
				clickClip.graphics.drawCircle(shapeData.location.x, shapeData.location.y, shapeData.width);
				clickClip.graphics.endFill();						
				_overlay.addChild(clickClip);
				
				var clickEntity:Entity = EntityUtils.createSpatialEntity(this, clickClip, _overlay);
				clickEntity.ignoreGroupPause = true;
				InteractionCreator.addToEntity(clickEntity, [InteractionCreator.CLICK]);
				clickEntity.get(Interaction).click.addOnce(Command.create(shapeClicked, step, shapeData));
				ToolTipCreator.addToEntity(clickEntity);
			}
		}
		
		private function drawEllipse(shapeData:ShapeData, step:StepData):void
		{
			_overlay.graphics.drawEllipse(shapeData.location.x, shapeData.location.y, shapeData.width, shapeData.height);
			
			if(!shapeData.interaction && !shapeData.signal)
			{
				var clickClip:Sprite = new Sprite();
				clickClip.graphics.beginFill(0xFFFFFF, .01);
				clickClip.graphics.drawEllipse(shapeData.location.x, shapeData.location.y, shapeData.width, shapeData.height);
				clickClip.graphics.endFill();						
				_overlay.addChild(clickClip);
				
				var clickEntity:Entity = EntityUtils.createSpatialEntity(this, clickClip, _overlay);
				clickEntity.ignoreGroupPause = true;
				InteractionCreator.addToEntity(clickEntity, [InteractionCreator.CLICK]);
				clickEntity.get(Interaction).click.addOnce(Command.create(shapeClicked, step, shapeData));
				ToolTipCreator.addToEntity(clickEntity);
			}
		}
		
		private function onComplete():void
		{
			if(gesture)
				GestureUtils.stop(gesture);
			
			SceneUtil.lockInput(this, false, false);
			_stepDatas = null;
			_container.removeChild(_overlay);
			this.parent.unpause();			
			complete.dispatch(this);
		}
		
		public var complete:Signal;
		private var _container:DisplayObjectContainer;
		private var _stepDatas:Vector.<StepData>;
		private var _overlay:Sprite;
		private var _currentTextfields:Array;
		private var _currentImages:Array;
		private var _currentCloses:Array;
		
		private const BLUR:Number = 20;
		private const OFFSET:Number = 50;
		
		public static const GROUP_ID:String 		= "tutorialGroup";
	}
}