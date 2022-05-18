package game.scenes.hub.profile.popups
{
	import com.adobe.utils.DictionaryUtil;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.hub.profile.groups.PhotoBoardGroup;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	
	public class PhotoBoardPopup extends Popup
	{
		private var left:Entity;
		private var right:Entity;
		
		private var content:MovieClip;
		
		private var photos:Array;
		private var images:Dictionary;
		private var index:int =0;
		private var photoContainer:MovieClip;
		private var photoBoard:PhotoBoardGroup;
		
		public function PhotoBoardPopup(container:DisplayObjectContainer=null, startIndex:int = 0)
		{
			super(container);
			photos = [];
			images = new Dictionary();
			index = startIndex;
			id = "photoBoardPopup";
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.darkenAlpha = .75;
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/profile/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["photoBoardPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("photoBoardPopup.swf", true) as MovieClip;
			// this loads the standard close button
			super.loadCloseButton();
			
			photoBoard = getGroupById(PhotoBoardGroup.GROUP_ID, parent) as PhotoBoardGroup;
			
			var content:MovieClip = screen.content;
			
			var clip:MovieClip = content["left"];
			left = ButtonCreator.createButtonEntity(clip, this, Command.create(scrollThroughImages, -1));
			clip = content["right"];
			right = ButtonCreator.createButtonEntity(clip, this, Command.create(scrollThroughImages, 1));
			photoContainer = content["photoContainer"];
			
			EntityUtils.visible(left, index>0);
			EntityUtils.visible(right, index < photoBoard.NumTemplates-1);
			
			photos = DictionaryUtil.getKeys(photoBoard.picDatas);
			photos.sort(PhotoBoardGroup.sortByDate);
			if(photos.length > 0)
				photoBoard.recreatePhoto(photos[index],placeImage);
			
			super.loaded();
		}
		
		private function scrollThroughImages(button:Entity, direction:int):void
		{
			if(photos.length <=1)
				return;
			index += direction;
			if(index <=0)
			{
				index = 0;
				EntityUtils.visible(left, false);
			}
			else
			{
				EntityUtils.visible(left);
			}
				
			if(index >= photos.length-1)
			{
				if(photos.length < photoBoard.NumTemplates)
				{
					photoBoard.retrieveMorePics(index);
					photoBoard.ready.addOnce(showNextPic);
					SceneUtil.lockInput(this);
					return;
				}
				EntityUtils.visible(right, false);
				index = photos.length -1;
			}
			else
			{
				EntityUtils.visible(right);
			}
				
			var photoName:String = photos[index];
			if(images.hasOwnProperty(photoName))
				placeImage(images[photoName]);
			else
			{
				SceneUtil.lockInput(this);
				photoBoard.recreatePhoto(photoName,placeImage);
			}
		}
		
		private function showNextPic(...args):void
		{
			photos = DictionaryUtil.getKeys(photoBoard.picDatas);
			photos.sort(PhotoBoardGroup.sortByDate);
			scrollThroughImages(null,0);
		}
		
		private function placeImage(sprite:Sprite):void
		{
			if(photoContainer.numChildren>0)
				photoContainer.removeChild(photoContainer.getChildAt(0));
			photoContainer.addChild(sprite);
			SceneUtil.lockInput(this, false);
		}
	}
}