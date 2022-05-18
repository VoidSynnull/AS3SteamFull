package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.backlot.BacklotEvents;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class MovieScript extends Popup
	{
		public function MovieScript(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/shared/";
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["movieScript.swf"]);
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset("movieScript.swf", true) as MovieClip;
			
			super.layout.centerUI(super.screen.content);
			
			setUpGame();
			
			super.loaded();
			super.loadCloseButton();
		}
		
		private function setUpGame():void
		{
			_content = super.screen.content as MovieClip;
			
			pages = new Vector.<Entity>();
			stickers = new Vector.<Entity>();
			
			for(var i:int = 1; i <= 4; i ++)
			{
				// set up page
				var page:MovieClip = _content.getChildByName("page"+i) as MovieClip;
				
				var pageEntity:Entity = EntityUtils.createMovingEntity(this, page, _content);
				
				pageEntity.add(new Audio());
				
				var interaction:Interaction = InteractionCreator.addToEntity(pageEntity,[InteractionCreator.DOWN, InteractionCreator.UP],page);
				ToolTipCreator.addToEntity(pageEntity);
				interaction.down.add(clickObject);
				interaction.up.add(releasePage);
				
				pages.push(pageEntity);
				
				// set up sticker
				var sticker:MovieClip = _content.getChildByName("sticker"+i) as MovieClip;
				var stickerEntity:Entity = EntityUtils.createMovingEntity(this, sticker, _content);
				
				stickerEntity.add(new Audio());
				
				TimelineUtils.convertClip(sticker, this,stickerEntity,null,false);
				
				var timeline:Timeline = stickerEntity.get(Timeline);
				timeline.gotoAndStop(i - 1);
				
				interaction = InteractionCreator.addToEntity(stickerEntity,[InteractionCreator.DOWN, InteractionCreator.UP],sticker);
				ToolTipCreator.addToEntity(stickerEntity);
				interaction.down.add(clickObject);
				interaction.up.add(releaseSticker);
				
				stickers.push(stickerEntity);
			}
			
			if(shellApi.checkEvent(_events.ORDERED_PAGES))
				orderThePages();
		}
		// continue working on a dragging system
		private function clickObject(entity:Entity):void
		{
			Audio(entity.get(Audio)).play("effects/pick_up_wrapper_01.mp3");
			// set up the entity to follow the mouse
			var inputSpatial:Spatial = shellApi.inputEntity.get(Spatial);
			var followTarget:FollowTarget = new FollowTarget();
			followTarget.target = inputSpatial;
			followTarget.rate = .5;
			
			// move the entity to the front and reset its parenting to default (content)
			var display:Display = entity.get(Display);
			display.setContainer(_content);
			display.moveToFront();
			
			// set the offset so that it moves from where you clicked (not the center)
			var difference:Point = new Point(entity.get(Spatial).x - inputSpatial.x, entity.get(Spatial).y - inputSpatial.y);
			followTarget.offset = difference;
			entity.add(followTarget);
			
			// check and see if any of the stickers have been stuck to pages and therefore moved infront of the page
			for(var i:int = 0; i < stickers.length; i++)
			{
				var followTargetSticker:FollowTarget = stickers[i].get(FollowTarget);
				if(followTargetSticker == null)
					continue;
				
				if(followTargetSticker.target == entity.get(Spatial))
				{
					stickers[i].get(Display).moveToFront();
				}
			}
		}
		
		private function releaseSticker(sticker:Entity):void
		{	
			Audio(sticker.get(Audio)).play("effects/put_misc_item_down_01.mp3");
			
			var display:Display = sticker.get(Display);
			
			var index:int = _content.numChildren;
			
			var overPage:Boolean = false;
			
			// checking to see if the sticker was placed on a page
			
			for(var i : int = 0; i < pages.length; i++)
			{
				var page:Display = pages[i].get(Display);
				
				if(!display.displayObject.hitTestObject(page.displayObject))
					continue;
				
				overPage = true;
				
				// checks to make sure the sticker gets placed on the top most page that the sticker is over
				if(page.displayObject.parent.getChildIndex(page.displayObject) < index)
				{
					var followTarget:FollowTarget = sticker.get(FollowTarget);
					followTarget.target = pages[i].get(Spatial);
					followTarget.offset.x = shellApi.inputEntity.get(Spatial).x - page.displayObject.x - _content.x;
					followTarget.offset.y = shellApi.inputEntity.get(Spatial).y - page.displayObject.y - _content.y;
					followTarget.rate = 1;
				}
			}
			
			if(!overPage)
				sticker.remove(FollowTarget);
			else
			{
				if(orderedTheScript())
				{
					trace("you ordered the pages");
					orderThePages();
				}
			}
		}
		
		private function orderedTheScript():Boolean
		{
			for(var i:int = 0; i < 4; i ++)
			{
				var stick:FollowTarget = stickers[i].get(FollowTarget);
				if(stick == null)
					return false;
				
				var page:Spatial = pages[i].get(Spatial);
				
				if(stick.target != page)
					return false;
			}
			
			return true;
		}
		
		private function orderThePages():void
		{
			for(var i:int = 0; i < 4; i ++)
			{
				stickers[i].remove(Interaction);
				
				var stickerDisplay:Display = stickers[i].get(Display);
				var pageDisplay:Display = pages[i].get(Display);
				
				var stickerSpatial:Spatial = stickers[i].get(Spatial);
				var pageSpatial:Spatial = pages[i].get(Spatial);
				
				var follow:FollowTarget = stickers[i].get(FollowTarget);
				
				var tweenSpeed:Number = 0;
				
				if(follow != null)
				{
					tweenSpeed = 2;
					stickers[i].remove(FollowTarget);
					stickerSpatial.x -= pageSpatial.x;
					stickerSpatial.y -= pageSpatial.y;
				}
				else
				{
					stickerSpatial.x = Math.random() * pageDisplay.displayObject.width / 1.5 - pageDisplay.displayObject.width / 3;
					stickerSpatial.y = Math.random() * pageDisplay.displayObject.height / 1.5 - pageDisplay.displayObject.height / 3;
				}
				
				stickerDisplay.setContainer(pageDisplay.displayObject);
				stickerDisplay.moveToFront();
				
				var tween:Tween = new Tween();
				
				var x:Number = shellApi.camera.camera.viewportWidth / 5 * i;
				
				var y:Number = shellApi.camera.camera.viewportHeight / 3 - 10 + Math.random() * 20;
				
				tween.to(pageSpatial, tweenSpeed, { x:x, y:y, onComplete:organizedPages });
				
				pages[i].add(tween);
			}
		}
		
		private function organizedPages():void
		{
			var closePopup:Boolean = !shellApi.checkEvent(_events.ORDERED_PAGES);
			shellApi.triggerEvent(_events.ORDERED_PAGES, true);
			if(closePopup)
				super.close();
		}
		
		private function releasePage(page:Entity):void
		{
			Audio(page.get(Audio)).play("effects/pick_up_wrapper_02.mp3");
			page.remove(FollowTarget);
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
		
		private var _content:MovieClip;
		
		private var pages:Vector.<Entity>;
		
		private var stickers:Vector.<Entity>;
		
		private var _events:BacklotEvents;
	}
}