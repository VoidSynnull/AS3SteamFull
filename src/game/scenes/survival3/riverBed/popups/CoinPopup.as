package game.scenes.survival3.riverBed.popups
{
	import com.greensock.easing.Back;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.motion.Draggable;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.data.ui.TransitionData;
	import game.scenes.survival3.Survival3Events;
	import game.systems.motion.DraggableSystem;
	import game.ui.popup.Popup;
	import game.util.ArrayUtils;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.Utils;
	
	public class CoinPopup extends Popup
	{
		private var bitmaps:Vector.<Bitmap> = new Vector.<Bitmap>();
		private var events:Survival3Events = new Survival3Events();
		private const NUM_COINS:int = 25;
		private const SHADOW:String = "shadow";
		
		public function CoinPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "CoinPopup";
			this.groupPrefix 		= "scenes/survival3/riverBed/coinPopup/";
			this.screenAsset 		= "coinPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, this.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Back.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Back.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function destroy():void
		{
			for each(var bitmap:Bitmap in this.bitmaps)
			{
				if(bitmap.bitmapData)
				{
					bitmap.bitmapData.dispose();
					bitmap.bitmapData = null;
				}
				
				this.bitmaps = null;
			}
			super.destroy();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			this.loadCloseButton();
			
			this.addSystem(new DraggableSystem());
			
			var centerX:Number = this.shellApi.viewportWidth * 0.5;
			var centerY:Number = this.shellApi.viewportHeight * 0.5;
			
			this.setupPurse(centerX, centerY);
			this.setupCoins(centerX, centerY);
			this.setupPage(centerX, centerY);
		}
		
		private function setupPurse(centerX:Number, centerY:Number):void
		{
			var clip:MovieClip 	= this.screen.content.purse;
			clip.x 				= centerX;
			clip.y 				= centerY;
			var bitmap:Bitmap 	= BitmapUtils.createBitmap(clip);
			
			this.bitmaps.push(bitmap);
			DisplayUtils.swap(bitmap, clip);
		}
		
		private function setupCoins(centerX:Number, centerY:Number):void
		{
			var content:DisplayObjectContainer = this.screen.content;
			var i:int;
			
			//Penny
			var entity:Entity = this.createCoin(content["copper_penny"], centerX, centerY);
			entity.get(Draggable).drag.addOnce(this.onPennyDrag);
			
			//Randomly bitmap a certain number of other coins.
			var coins:Array = ["copper_1", "copper_2", "nickel_1", "nickel_2", "nickel_3", "gold_1", "twit_1"];
			for(i = 0; i < NUM_COINS; ++i)
			{
				this.createCoin(content[ArrayUtils.getRandomElement(coins)], centerX, centerY);
			}
			
			//Remove old, unbitmapped reference assets.
			for(i = 0; i < 7; ++i)
			{
				content.removeChild(content[coins[i]]);
			}
			content.removeChild(content["copper_penny"]);
		}
		
		private function createCoin(clip:MovieClip, centerX:Number, centerY:Number):Entity
		{
			var sprite:Sprite 	= BitmapUtils.createBitmapSprite(clip, 0.75);
			sprite.x 			= centerX + Utils.randNumInRange(-230, 230);
			sprite.y 			= centerY + Utils.randNumInRange(-180, 180);
			sprite.name			= clip.name;
			
			this.screen.content.addChild(sprite);
			this.bitmaps.push(sprite.getChildAt(0));
			
			var bounds:Rectangle = sprite.getBounds(sprite);
			
			//Making a Shape first so I can make an ellipse to cover the coin, then bitmapping it.
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0x000000, 0.75);
			shape.graphics.drawEllipse(bounds.left, bounds.top, bounds.width, bounds.height);
			shape.graphics.endFill();
			
			var bitmap:Bitmap = BitmapUtils.createBitmap(shape);
			bitmap.x = bounds.left;
			bitmap.y = bounds.top;
			bitmap.name = SHADOW;
			sprite.addChild(bitmap);
			this.bitmaps.push(bitmap);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			
			var draggable:Draggable = new Draggable();
			draggable.drag.addOnce(this.onDrag);
			draggable.drag.add(this.coinSound);
			entity.add(draggable);
			
			return entity;
		}
		
		private function coinSound(entity:Entity):void
		{
			var name:String = entity.get(Display).displayObject.name;
			
			if(name.indexOf("copper") != -1) 		name = "2";
			else if(name.indexOf("nickel") != -1) 	name = "1";
			else if(name.indexOf("gold") != -1) 	name = "4";
			else if(name.indexOf("twit") != -1) 	name = "3";
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "coin_0" + name + ".mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function onDrag(entity:Entity):void
		{
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(entity.get(Spatial), 0.25, {scaleX:0.75, scaleY:0.75, ease:Back.easeOut});
			
			var display:DisplayObject = entity.get(Display).displayObject;
			display = DisplayObjectContainer(display).getChildByName(SHADOW);
			tween.to(display, 0.25, {alpha:0, onComplete:this.removeShadow, onCompleteParams:[display]});
		}
		
		private function removeShadow(display:DisplayObject):void
		{
			display.parent.removeChild(display);
		}
		
		private function onPennyDrag(entity:Entity):void
		{
			entity.remove(Draggable);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_01b.mp3", 1, false, [SoundModifier.EFFECTS]);
			this.removed.addOnce(this.onRemoved);
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			var x:Number 	= this.shellApi.viewportWidth * 0.5;
			var y:Number 	= this.shellApi.viewportHeight * 0.5;
			tween.to(entity.get(Spatial), 3, {x:x, y:y, onComplete:this.close});
		}
		
		private function onRemoved(group:Group):void
		{
			this.shellApi.getItem(this.events.PENNY, null, true);
		}
		
		private function setupPage(centerX:Number, centerY:Number):void
		{
			var clip:MovieClip 	= this.screen.content.page;
			clip.x 				= centerX;
			clip.y 				= centerY;
			var sprite:Sprite 	= BitmapUtils.createBitmapSprite(clip);
			
			this.bitmaps.push(sprite.getChildAt(0));
			
			DisplayUtils.swap(sprite, clip);
			DisplayUtils.moveToTop(sprite);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
			ToolTipCreator.addToEntity(entity);
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			interaction.click.add(this.onPageClick);
		}
		
		private function onPageClick(entity:Entity):void
		{
			var interaction:Interaction = entity.get(Interaction);
			if(!interaction.lock)
			{
				interaction.lock = true;
				
				var spatial:Spatial = entity.get(Spatial);
				var tween:Tween 	= this.getGroupEntityComponent(Tween);
				var object:Object 	= {ease:Back.easeInOut, onComplete:this.onPageTweenComplete, onCompleteParams:[interaction]};
				
				if(spatial.x < 0)
				{
					DisplayUtils.moveToTop(entity.get(Display).displayObject);
					object.x = this.shellApi.viewportWidth * 0.5;
				}
				else
				{
					object.x = -250;
				}
				
				tween.to(spatial, 0.75, object);
			}
		}
		
		private function onPageTweenComplete(interaction:Interaction):void
		{
			interaction.lock = false;
		}
	}
}