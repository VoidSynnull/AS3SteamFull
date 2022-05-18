package game.scenes.timmy.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.ui.popup.HandBookPopup;
	import game.util.DisplayUtils;
	import game.util.PerformanceUtils;
	
	public class DetectiveLogPopup extends HandBookPopup
	{
		private const FOREGROUND:String 		=	"foreground";
		private const OFFSET_X:Number 			=	13;
		
		public function DetectiveLogPopup( container:DisplayObjectContainer = null )
		{
			super(container);
			this._ringed 						=	true;
		}
		
		override protected function setupPages():void
		{
			super.setupPages();
			
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM )
			{
				var pageNum:uint = 1;
				var page:Entity;
				for( pageNum; pageNum <= _totalPages; pageNum++ )
				{
					page = getEntityById( this.PAGE + pageNum );
					if( page )
					{
						Spatial( page.get( Spatial )).x += OFFSET_X;
					}
				}
			}
		}
		
		override protected function pageFlip( entity:Entity, handler:Function = null ):void
		{
			super.pageFlip( entity, handler );
			var contents:MovieClip = super.screen.contents as MovieClip;
			//move fg stuff to top
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_MEDIUM )
			{
				DisplayUtils.moveToTop( contents.getChildByName( this.FOREGROUND ));
			}
		}
		
		override protected function openCover( entity:Entity, other:Entity, opening:Boolean, isPage:Boolean = false, handler:Function = null ):void
		{
			super.openCover( entity, other, opening, isPage, handler );
			var contents:MovieClip = super.screen.contents as MovieClip;
			//move fg stuff to top
			DisplayUtils.moveToTop( contents.getChildByName( this.FOREGROUND ));
		}
	}
}