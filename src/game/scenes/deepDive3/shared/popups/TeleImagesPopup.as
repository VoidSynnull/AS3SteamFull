package game.scenes.deepDive3.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.ui.TransitionData;
	import game.scenes.deepDive3.laboratory.Laboratory;
	import game.scenes.deepDive3.livingQuarters.LivingQuarters;
	import game.scenes.deepDive3.mainDeck.MainDeck;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class TeleImagesPopup extends Popup
	{
		public function TeleImagesPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
				
			this.pauseParent = true;
			this.autoOpen = true;
			this.groupPrefix = "scenes/deepDive3/shared/popups/";
			this.screenAsset = "teleImagesPopup.swf";
			
			if(super.shellApi.currentScene is Laboratory){
				_imageIndexStart = 0;
			}
			else if(super.shellApi.currentScene is MainDeck){
				_imageIndexStart = 2;
			}
			else if(super.shellApi.currentScene is LivingQuarters){
				_imageIndexStart = 4;
			}
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.preparePopup();
			setupContent();
			super.groupReady();
			
			_step = 0;
			_fadeIn = true;
			EntityUtils.visible(_imageLayer1,true);
			if( _imageLayer2 ) { EntityUtils.visible(_imageLayer1,true); }
			fade();
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;

			var clip:MovieClip = content["content"] as MovieClip;
			trimImages( clip );
			BitmapUtils.convertContainer( clip, PerformanceUtils.defaultBitmapQuality);
			_imageLayer1 = EntityUtils.createSpatialEntity( this, clip);
			EntityUtils.visible(_imageLayer1,false,true);

			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST)
			{
				clip = content["content2"] as MovieClip;
				trimImages( clip );
				BitmapUtils.convertContainer( clip, PerformanceUtils.defaultBitmapQuality);
				_imageLayer2 = EntityUtils.createSpatialEntity( this, clip);
				EntityUtils.visible(_imageLayer2,false,true);
				
				// TODO :: This needs to be fixed, doesn't, isn't working anymore,will investigate. -Bard
				var filterClip:Sprite = content["texture"] as MovieClip;
				clip.mask = filterClip;
				_filterTexture = EntityUtils.createDisplayEntity( this, filterClip);
				
				//content.removeChild(content["texture"]);
			} 
			else 
			{
				content.removeChild(content["content2"]);
				content.removeChild(content["texture"]);
			}
		}
		
		private function trimImages( imageContainer:MovieClip ):void
		{
			var clip:Sprite = imageContainer.getChildAt( _imageIndexStart ) as Sprite;
			clip.visible = false;		// start out with second image invisible
			DisplayUtils.moveToTop( clip);
			
			clip = imageContainer.getChildAt( _imageIndexStart ) as Sprite;
			DisplayUtils.moveToTop( clip);

			while( imageContainer.numChildren > 2 )
			{
				imageContainer.removeChildAt(0);
			}
		}
		
		private function fade():void
		{
			if( _fadeIn )
			{
				_fadeIn = false;
				_step++;
				EntityUtils.getDisplay(_imageLayer1).alpha = 0;
				TweenUtils.entityTo( _imageLayer1, Display, FADE_DURATION, {alpha:.8} );
				
				if( _imageLayer2 )
				{
					EntityUtils.getDisplay(_imageLayer2).alpha = 0;
					TweenUtils.entityTo( _imageLayer2, Display, FADE_DURATION, {alpha:.8} );
				}

				SceneUtil.delay( this, (IMAGE_DURATION + FADE_DURATION), fade );
			}
			else
			{
				_fadeIn = true;
				var completeFunction:Function = ( _step < 2 ) ? nextImage : super.close;
				TweenUtils.entityTo( _imageLayer1, Display, FADE_DURATION, {alpha:0, onComplete:completeFunction} );
				
				if( _imageLayer2 )
				{
					TweenUtils.entityTo( _imageLayer2, Display, FADE_DURATION, {alpha:0} );
				}
			}
		}
		
		private function nextImage():void
		{
			EntityUtils.getDisplayObject(_imageLayer1).getChildAt(1).visible = false;
			EntityUtils.getDisplayObject(_imageLayer1).getChildAt(0).visible = true;
			if( _imageLayer2 )
			{
				EntityUtils.getDisplayObject(_imageLayer2).getChildAt(1).visible = false;
				EntityUtils.getDisplayObject(_imageLayer2).getChildAt(0).visible = true;
			}
			fade();
		}
		
		private const TOTAL_IMAGES:int = 6;
		private const IMAGE_DURATION:Number = 4.5;	// in seconds
		private const FADE_DURATION:Number = .5;

		private var _imageIndexStart:int = 0;
		private var _imageLayer1:Entity;
		private var _imageLayer2:Entity;
		private var _filterTexture:Entity;
		private var _fadeIn:Boolean;
		private var _step:int = 0;
	}
}