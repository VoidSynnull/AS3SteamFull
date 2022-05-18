package game.scenes.con3.portal.subscenes
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.DisplayGroup;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.animation.Animation;
	import game.scene.template.CutSubScene;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	public class PowerUpSubScene extends CutSubScene
	{		
		public function PowerUpSubScene( container:DisplayObjectContainer = null )
		{
			super(container);
		}
		
		override public function setup( subClip:MovieClip, nextSubScene:CutSubScene = null, completeHandler:Function = null, destroyOnComplete:Boolean = true, autoBitmap:Boolean = true  ):void
		{
			_sceneClip = subClip;
			_nextSubScene = nextSubScene;
			_completeHandler = completeHandler;
			_destroyOnComplete = destroyOnComplete
			
			_sceneClip.parent.removeChild( _sceneClip );
			_sceneClip.gotoAndStop(1);
			
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality; 
			
			_subSceneEntity = TimelineUtils.convertClip( _sceneClip as MovieClip, this, null, null, false );
			_subSceneEntity.add( new Sleep( true, true ) );
			
			_rays = EntityUtils.createSpatialEntity( this, subClip[ "rays" ]);
			BitmapTimelineCreator.convertToBitmapTimeline( _rays );
			
			_shieldPower 	= setupItem( SHIELD, bitmapQuality );
			_glovesPower 	= setupItem( GLOVES, bitmapQuality );
			_bowPower 		= setupItem( BOW, bitmapQuality );
		}
		
		private function setupItem( itemName:String, bitmapQuality:Number ):Entity
		{
			var itemClip:MovieClip = _sceneClip[itemName];
			var entity:Entity = TimelineUtils.convertClip( itemClip, this, null, _subSceneEntity, false);
			entity.add( new Display(itemClip) );
			
			super.convertContainer( itemClip, bitmapQuality ); 
			entity.add( new Sleep( true, true ) );
			//_sceneClip.removeChild(itemClip);
			return entity
		}
		
		override public function start( startLabel:String = "" ):void
		{
			//add to groupContainer
			(super.parent as DisplayGroup).groupContainer.addChild( _sceneClip );
			(_subSceneEntity.get( Sleep ) as Sleep).sleeping = false;
			var timeline:Timeline = _subSceneEntity.get( Timeline );
			timeline.gotoAndStop(startLabel);

			// determine item
			setItem( startLabel );
			
			// set background color
			ColorUtil.colorize( _sceneClip["bg"], _itemColor );
			
			//EntityUtils.getDisplay(_activeItem).setContainer(_sceneClip);
			(_activeItem.get(Sleep) as Sleep).sleeping = false;
			EntityUtils.visible(_activeItem, true);
			//TimelineUtils.playAll(_activeItem);
			timeline = _activeItem.get( Timeline );
			timeline.handleLabel( Animation.LABEL_ENDING, ending );
			timeline.gotoAndPlay(0);
			
			(_rays.get(Timeline) as Timeline).playing = true;
		}
		
		override public function ending():void
		{
			// remove entity
			_sceneClip.removeChild( EntityUtils.getDisplayObject(_activeItem) );
			(_activeItem.get(Sleep) as Sleep).sleeping = true;
			this.removeEntity( _activeItem, true );
			(_rays.get(Timeline) as Timeline).playing = false;
			//(_subSceneEntity.get(Timeline) as Timeline).playing = false;
			
			super.ending();
		}
		
		public function setItem (item:String ):void
		{
			switch(item)
			{
				case GLOVES:
				{
					_itemColor = 0x003348;
					_activeItem = _glovesPower;
					break;
				}
					
				case SHIELD:
				{
					_itemColor = 0x0A2D2E
					_activeItem = _shieldPower;
					break;
				}

				case BOW:
				{
					_itemColor = 0x13261B;
					_activeItem = _bowPower;
					break;
				}
					
				default:
				{
					break;
				}
			}
		}
		
		public const SHIELD:String 	= "shield";
		public const GLOVES:String 	= "gloves";
		public const BOW:String 	= "bow";
		
		private var _rays:Entity;
		private var _shieldPower:Entity;
		private var _glovesPower:Entity;
		private var _bowPower:Entity;
		private var _activeItem:Entity;
		private var _itemColor:Number;
	}
}