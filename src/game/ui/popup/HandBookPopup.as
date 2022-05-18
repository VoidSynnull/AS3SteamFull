package game.ui.popup
{	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.ui.ToolTipType;
	import game.scenes.survival1.shared.components.PageComponent;
	import game.scenes.timmy.shared.popups.DetectiveLogPopup;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class HandBookPopup extends Popup
	{
		private const TOTAL_PAGES:String 		= "totalPages";
		private const PAGE_EVENT:String 		= "pageEvent";
		private const BOOK_EVENT:String 		= "bookEvent";
		private const SCREEN_ASSET:String 		= "screenAsset";
		private const GROUP_PREFIX:String 		= "groupPrefix";
		
		private const WRAPPER_01:String 		= "paper_flap_01.mp3"
		private const WRAPPER_02:String 		= "pick_up_wrapper_02.mp3";
		
		private const COVER_FRONT:String 		= "coverpage";
		private const REVERSE_PAGE:String 		= "reversePage";
		private const COVER_BACK:String 		= "coverpageBack";
		private const BOOK_BASE:String 			= "book";
		protected const PAGE:String 			= "page";
		private const FLIP_PAGES:String 		= "flipPages";
		
		private var _pageCollectedEvent:String;
		private var _bookCollectedEvent:String;
		
		private var _pages:Vector.<BitmapWrapper>;
		private var _pageBackBitmap:BitmapData;
		
		private var _coverScale:Number;
		private var _flipPages:Boolean = false;
		private var _haveBook:Boolean = false;
		private var _coverClosed:Boolean = true;
		
		private var _pageDistance:Number;
		protected var _totalPages:uint;
		protected var _pagesCollected:Array		=	[];
		protected var _currentPageNumber:int	=	0;
		protected var _targetPage:String;
		
		protected var _ringed:Boolean 			=	false;
		
		private var leftClick:Entity;
		private var rightClick:Entity;
		
		public function HandBookPopup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		override public function destroy():void
		{
			// destroy bitmaps
			for (var i:int = 0; i < _pages.length; i++) 
			{
				_pages[i].destroy();
			}
			_pages.length = 0;
			_pages = null;
			if( _pageBackBitmap )
			{
				_pageBackBitmap.dispose();
				_pageBackBitmap = null;
			}
			
			super.destroy();
		}
		
		public function configData( screenAsset:String, groupPrefix:String = null, pages:uint = 0, pageEvent:String = null, bookEvent:String = null ):void
		{	
			if(groupPrefix == null)
				super.groupPrefix = "scenes/"+shellApi.island+"/shared/popups/"
			else
				super.groupPrefix = groupPrefix;
			super.screenAsset = screenAsset;
			_totalPages = pages;
			_pageCollectedEvent = pageEvent;
			_bookCollectedEvent = bookEvent;
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.darkenBackground = true;
			super.init( container );
			super.load();
		}
		
		override public function setParams(params:ParamList):void
		{
			for each (var param:ParamData in params.params)
			{
				if(param.id == TOTAL_PAGES)
					_totalPages = uint(param.value);
				
				if(param.id == PAGE_EVENT)
					_pageCollectedEvent = String(param.value);
				
				if(param.id == BOOK_EVENT)
					_bookCollectedEvent = String(param.value);
				
				if(param.id == SCREEN_ASSET)
					super.screenAsset = String(param.value);
				
				if(param.id == GROUP_PREFIX)
					super.groupPrefix = String(param.value);
				
				if(param.id == FLIP_PAGES)
					_flipPages = Boolean(param.value);
			}
		}
		
		override public function loaded():void
		{	
			super.preparePopup();
			
			_pages = new Vector.<BitmapWrapper>();
			super.layout.centerUI( super.screen.contents );
			loadCloseButton();
			
			_haveBook = shellApi.checkEvent(_bookCollectedEvent);
			
			if(!_haveBook)
				_haveBook = shellApi.checkEvent( GameEvent.GOT_ITEM + _bookCollectedEvent );
			
			setupPages();
			
			super.groupReady();
		}
		
		
		protected function setupPages():void
		{			
			var clip:MovieClip;
			var contents:MovieClip = super.screen.contents as MovieClip;
			var display:Display;
			var frontEntity:Entity;
			var backEntity:Entity;
			var interaction:Interaction;
			
			var page:PageComponent;
			var spatial:Spatial;
			
			_pageDistance = contents["page1"].width;
			
			// create pageback BitmapData
			
			if( _haveBook )
			{
				// COVER FRONT
				clip = contents.getChildByName( this.COVER_FRONT ) as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				frontEntity = createPage( clip, this.COVER_FRONT, true );//, false );
				_pagesCollected.push( frontEntity );
				_coverScale = clip.scaleX;
				
				// COVER BACK
				clip = contents.getChildByName( this.COVER_BACK ) as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				backEntity = createPage( clip, this.COVER_BACK, false )//, false );
				EntityUtils.visible( backEntity, false );
				
				// BOOK BACKGROUND
				clip = contents.getChildByName( this.BOOK_BASE ) as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )	// if higher quality, bitmap the entire page, else leave as vector
				{
					//_pages.push( DisplayUtils.convertToBitmapSpriteBasic( clip["content"], null, clip.scaleX ));
					_pages.push( DisplayUtils.convertToBitmapSprite( clip, null, clip.scaleX ));
				}
			}
			else
			{	
				contents.removeChild( contents.getChildByName( this.COVER_FRONT ) );
				contents.removeChild( contents.getChildByName( this.COVER_BACK ) );
				contents.removeChild( contents.getChildByName( this.BOOK_BASE ) );
			}
			
			var pageNum:uint = 1;
			for( pageNum; pageNum <= _totalPages; pageNum++ )
			{
				clip = contents.getChildByName( this.PAGE + pageNum ) as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				if( shellApi.checkEvent( GameEvent.GOT_ITEM + _pageCollectedEvent + pageNum ) || shellApi.checkEvent(_pageCollectedEvent + pageNum))
				{
					_pagesCollected.push( createPage( clip, this.PAGE + pageNum, !_haveBook ));
					if( _flipPages )
					{
						clip = contents.getChildByName( this.REVERSE_PAGE + pageNum ) as MovieClip
						clip.mouseChildren = false;
						clip.mouseEnabled = false;
						backEntity = createPage( clip, this.REVERSE_PAGE + pageNum, !_haveBook);
						EntityUtils.visible( backEntity, false );
					}
				}
				else
				{
					contents.removeChild( clip);
					if( _flipPages )
					{
						clip = contents.getChildByName( this.REVERSE_PAGE + pageNum ) as MovieClip;
						clip.mouseChildren = false;
						clip.mouseEnabled = false;
						contents.removeChild( clip );
					}
				}
			}
			tracePages();
			// clicks
			createPageInteractions(true,true);
		}
		
		private function tracePages():void
		{
			trace("CURR PAGE: "+_currentPageNumber)
			for (var i:int = 0; i < _pagesCollected.length; i++) 
			{
				trace("PAGE: "+_pagesCollected[i].get(Id).id+", IsLeft: "+PageComponent(_pagesCollected[i].get(PageComponent)).isLeft);
			}
			SceneUtil.delay(this, 2.0, tracePages);
		}
		
		protected function createPage( clip:MovieClip, id:String, addInteractivity:Boolean = true ):Entity//, standardPage:Boolean = true ):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			var display:Display = entity.get( Display );
			
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM  )		// if higher quality, bitmap the entire page, else leave as vector
			{
				var bitmapWrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, clip.scaleX );
				display.refresh( bitmapWrapper.sprite );
				_pages.push( bitmapWrapper);
			}
			
			entity.add( new Id( id ));
			entity.add( new PageComponent());
			entity.add( new Tween());
			
			/*			if( addInteractivity )
			{
			
			addPageInteractivity( entity );
			}*/
			
			return entity;
		}
		
		protected function addPageInteractivity( entity:Entity, add:Boolean = true ):void
		{
			if( add )
			{
				ToolTipCreator.addToEntity( entity );
				
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				Interaction( entity.get( Interaction )).click.add( pageFlip );
			}
			else
			{
				ToolTipCreator.removeFromEntity( entity );
				
				Interaction( entity.get(Interaction) ).click.remove( pageFlip );
				entity.remove(Interaction);
			}
		}
		
		protected function createPageInteractions(addLeft:Boolean = false, addRight:Boolean = true):void
		{
			var clip:MovieClip;
			if(addLeft){
				clip = this.screen.contents["leftClick"];
				leftClick = EntityUtils.createSpatialEntity(this, clip);
				var leftInt:Interaction = InteractionCreator.addToEntity(leftClick,[InteractionCreator.CLICK]);
				leftInt.click.addOnce(flipRight);
				ToolTipCreator.addToEntity(leftClick);
			}
			
			if(addRight){
				clip = this.screen.contents["rightClick"];
				rightClick = EntityUtils.createSpatialEntity(this, clip);
				var rightInt:Interaction = InteractionCreator.addToEntity(rightClick,[InteractionCreator.CLICK]);
				rightInt.click.addOnce(flipLeft);
				ToolTipCreator.addToEntity(rightClick);
			}
		}
		
		private function flipLeft(ent:Entity):void
		{
			var inter:Interaction = leftClick.get(Interaction);
			inter.click.removeAll();
			// find next page, flip it
			var curr:Entity = _pagesCollected[_currentPageNumber];
			if(_currentPageNumber +1 < _pagesCollected.length){
				var next:Entity = _pagesCollected[_currentPageNumber++];
				if(next){
					pageFlip(next, resetFlips);	
				}
				else{
					resetFlips();
				}
			}
			else if(curr){
				// flip final page
				pageFlip(curr, resetFlips);
				_currentPageNumber = _pagesCollected.length;
			}
			else{
				resetFlips();
			}
		}
		
		private function flipRight(ent:Entity):void
		{
			var inter:Interaction = rightClick.get(Interaction);
			inter.click.removeAll();
			// find prev page, flip it
			if(_currentPageNumber > 0){
				var prev:Entity = _pagesCollected[_currentPageNumber-1];
				if(prev){
					var pageId:Id = prev.get(Id);
					var rev:Entity;
					if(pageId.id == COVER_FRONT){
						rev = getEntityById(COVER_BACK);
					}
					else if(pageId.id.indexOf(PAGE) == 0){
						rev = getEntityById(REVERSE_PAGE + pageId.id.substr(4));
						if(!rev){
							// no reverse page
							rev = prev;
						}
					}
					if(rev){
						pageFlip(rev, resetFlips);
						_currentPageNumber--;
					}
					else{
						resetFlips();
					}
				}
				else{
					resetFlips();
				}
			}else{
				resetFlips();
			}
		}	
		
		private function resetFlips(...p):void
		{
			trace("RESET FLIP")
			// left
			var inter:Interaction = rightClick.get(Interaction);
			inter.click.removeAll();
			inter.click.addOnce(flipLeft);
			// right
			inter = leftClick.get(Interaction);
			inter.click.removeAll();
			inter.click.addOnce(flipRight);
		}
		
		protected function pageFlip( entity:Entity, handler:Function = null ):void
		{
			var pageId:Id = entity.get( Id );
			trace("pageID:"+pageId.id)
			var tween:Tween = entity.get( Tween );
			var spatial:Spatial = entity.get( Spatial );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + WRAPPER_01 );
			if( pageId.id.indexOf( this.PAGE ) == 0 || pageId.id.indexOf( this.REVERSE_PAGE ) == 0 )
			{
				// normal page flip
				var page:PageComponent = entity.get( PageComponent );
				var value:Number;
				
				// toggle left/right state
				if( page.isLeft )
				{
					page.isLeft = false;
					value = _pageDistance;
				}
				else
				{
					page.isLeft = true;
					value = -_pageDistance;
				}
				
				if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
				{					
					if( _flipPages )
					{
						var reversePage:Entity;
						if( pageId.id.indexOf( this.REVERSE_PAGE ) == 0 )
						{
							reversePage = getEntityById( PAGE + pageId.id.substr( 11 ));							
						}
						else
						{
							reversePage = getEntityById( REVERSE_PAGE + pageId.id.substr( 4 ));
						}
						Spatial(reversePage.get(Spatial)).scaleX = 0;
						// '3d' flip enabled
						tween.to( spatial, .20, { scaleX:0,onComplete:openCover, onCompleteParams : [ entity, reversePage, false, true, handler ]});
					}
					else
					{
						tween.to( spatial, .20, { x : spatial.x + value, onComplete:handler });
					}
				}
				else
				{
					trace("value:: "+value)
					spatial.x += value;
					if( _flipPages )
					{
						if( pageId.id.indexOf( this.REVERSE_PAGE ) == 0 )
						{
							reversePage = getEntityById( PAGE + pageId.id.substr( 11 ));							
						}
						else
						{
							reversePage = getEntityById( REVERSE_PAGE + pageId.id.substr( 4 ));
						}		
						Spatial(reversePage.get(Spatial)).x += -value;
						DisplayUtils.moveToTop( EntityUtils.getDisplayObject( reversePage ));
					}
					if( _ringed )
					{
						DisplayUtils.moveToTop( EntityUtils.getDisplayObject( entity ));
					}	
					handler();
				}
				
				if( !_ringed )
				{
					DisplayUtils.moveToTop( EntityUtils.getDisplayObject( entity ));
				}
			}
			else
			{
				// cover page flip
				var otherCover:Entity;
				var open:Boolean;
				if(pageId.id == COVER_FRONT)
				{
					otherCover = super.getEntityById( this.COVER_BACK );
					open = true;
				}
				else
				{
					otherCover = super.getEntityById( this.COVER_FRONT );
					open = false;
				}
				
				//addPageInteractivity(entity, false);
				
				if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
				{
					Spatial(otherCover.get(Spatial)).scaleX = 0;
					tween.to( spatial, .25, { scaleX:0,onComplete:openCover, onCompleteParams : [ entity, otherCover, open, false, handler ]});
				}
				else
				{
					handler();
					EntityUtils.visible( entity, false );
					EntityUtils.visible( otherCover, true );
					//addPageInteractivity( otherCover, true );
					DisplayUtils.moveToTop( EntityUtils.getDisplayObject( otherCover ));
					givePagesInteractivity( open );
				}
			}
		}
		
		protected function givePagesInteractivity( add:Boolean, isPage:Boolean = false ):void
		{
			for ( var pageNum:int = 1; pageNum <= _totalPages; pageNum++) 
			{
				var pageEntity:Entity = isPage ? getEntityById( this.REVERSE_PAGE + pageNum ) : getEntityById( this.PAGE + pageNum );
				if( pageEntity != null )
				{
					//addPageInteractivity( pageEntity, add );
				}
			}
		}
		
		protected function openCover(cover:Entity, other:Entity, opening:Boolean, isPage:Boolean = false, handler:Function = null):void
		{
			var tween:Tween = other.get(Tween);
			var spatial:Spatial = other.get(Spatial);
			EntityUtils.visible( other, true );
			EntityUtils.visible( cover, false );
			DisplayUtils.moveToTop( EntityUtils.getDisplayObject( other ) );
			tween.to( spatial, .25, { scaleX:_coverScale,onComplete:coverOpened, onCompleteParams : [ cover, other, true, isPage, handler ]});
		}
		
		protected function coverOpened(cover:Entity, other:Entity, opening:Boolean, isPage:Boolean, handler:Function = null):void
		{
			//addPageInteractivity( other, true );
			givePagesInteractivity(opening, isPage);
			
			if( handler )
			{
				handler();
			}
		}
		
		// OPEN TO CERTAIN PAGE
		public function openToPage( detectivePopup:DetectiveLogPopup, pageNumber:int ):void
		{
			_targetPage 						=	PAGE + pageNumber;
			flipToPage();
		}
		
		private function flipToPage():void
		{
			var pageId:Id 						=	_pagesCollected[ _currentPageNumber ].get( Id );
			
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
			{
				if( _targetPage != pageId.id )
				{
					pageFlip( _pagesCollected[ _currentPageNumber ], flipToPage );
					_currentPageNumber++;
				}
				else
				{
					SceneUtil.lockInput( shellApi.currentScene, false );
				}
			}
			else
			{
				var value:Number 				=	_pageDistance;
				var pageNum:uint 				=	1;
				var currentPage:Entity;
				var onPage:Boolean 				=	false;
				
				var cover:Entity 				=	super.getEntityById( this.COVER_FRONT );
				var backCover:Entity 			=	super.getEntityById( this.COVER_BACK );
				var page:PageComponent;
				
				EntityUtils.visible( cover, false );
				EntityUtils.visible( backCover, true );
				//addPageInteractivity( backCover, true );
				givePagesInteractivity( true );
				
				for( pageNum; pageNum <= _pagesCollected.length; pageNum++ )
				{
					if( !onPage )
					{
						currentPage 			=	_pagesCollected[ pageNum ];
						page 					=	currentPage.get( PageComponent );
						pageId 					=	currentPage.get( Id );
						
						if( _targetPage == pageId.id )
						{
							// stop at target page
							onPage 				=	true;
							page.isLeft 		=	false;
							_currentPageNumber = pageNum;
						}
						else
						{
							//push prevs to left side
							Spatial( currentPage.get( Spatial )).x -= value;
							DisplayUtils.moveToTop( Display( currentPage.get( Display )).displayObject );
							page.isLeft 		=	true;
						}
					}
				}
				
				SceneUtil.lockInput( shellApi.currentScene, false );
			}
		}
	}
}