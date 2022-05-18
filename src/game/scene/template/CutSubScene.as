package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	public class CutSubScene extends DisplayGroup
	{
		public function CutSubScene( container:DisplayObjectContainer = null )
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			setup( _sceneClip, _nextSubScene, _completeHandler, _destroyOnComplete, _autoBitmap );
			super.groupReady();
		}
		
		public function setup( subClip:MovieClip, nextSubScene:CutSubScene = null, completeHandler:Function = null, destroyOnComplete:Boolean = true, autoBitmap:Boolean = true  ):void
		{
			_sceneClip = subClip;
			_nextSubScene = nextSubScene;
			_completeHandler = completeHandler;
			_destroyOnComplete = destroyOnComplete
			
			_sceneClip.parent.removeChild( _sceneClip );
			_sceneClip.gotoAndStop(1);
			
			_subSceneEntity = setupTimelines( _sceneClip );	//EntityUtils.createSpatialEntity( _parentCutScene, _sceneClip );
			// listen for end
			_subSceneEntity.add( new Sleep( true, true ) );
			
			if( autoBitmap )
			{
				setupBitmapping( _sceneClip );
			}
		}
		
		protected function setupTimelines( clip:DisplayObjectContainer ):Entity
		{
			return TimelineUtils.convertAllClips( clip, null, this, false );
		}
		
		protected function setupBitmapping( clip:DisplayObjectContainer, quality:Number = NaN ):void
		{
			if( isNaN(quality) ) { quality = PerformanceUtils.defaultBitmapQuality; } 
			this.convertContainer( clip, quality );
		}
		
		public function setupCharacter( charEntity:Entity, charContainer:DisplayObjectContainer):void
		{
			_charContainer = charContainer;
			DisplayUtils.removeAllChildren(_charContainer);
			EntityUtils.getDisplay(charEntity).setContainer(_charContainer);
		}

		public function start( startLabel:String = "" ):void
		{
			//add to groupContainer
			(super.parent as DisplayGroup).groupContainer.addChild( _sceneClip );
			if( _subSceneEntity )
			{
				(_subSceneEntity.get( Sleep ) as Sleep).sleeping = false;
			}

			var timeline:Timeline = _subSceneEntity.get( Timeline );
			timeline.handleLabel( Animation.LABEL_ENDING, ending );
			TimelineUtils.playAll( _subSceneEntity );

			/*
			// NOTE :: Want to allow defining startLabel, but it gets tricky with the nested children.... - bard
			if( startLabel == "" )
			{
				timeline.gotoAndPlay(1);
			}
			else
			{
				timeline.gotoAndPlay(startLabel);
			}
			*/
		}
		
		/**
		 * For override, handles 
		 * 
		 */
		protected function onLabelHandler( ):void
		{
			// be default listen for end
		}
		
		public function ending():void
		{
			//remove from groupContainer
			(super.parent as DisplayGroup).groupContainer.removeChild( _sceneClip );
			TimelineUtils.stopAll(_subSceneEntity);
			// remove player if it has been added
			if( _charContainer )
			{
				DisplayUtils.removeAllChildren(_charContainer);
			}

			// check for next subScene
			if( _completeHandler != null )
			{
				_completeHandler( this, _nextSubScene );
			}
			else if ( _nextSubScene != null )
			{
				_nextSubScene.start();
			}
			
			//check for destroy
			
			if( _destroyOnComplete )
			{
				super.parent.removeGroup(this, true);
			}
			else
			{
				(_subSceneEntity.get( Sleep ) as Sleep).sleeping = true;
			}
		}
		
		public function get subSceneEntity():Entity
		{
			return _subSceneEntity;
		}

		protected var _sceneClip:MovieClip;
		public function get sceneClip():MovieClip	{ return _sceneClip; }
		protected var _charContainer:DisplayObjectContainer;
		
		protected var _destroyOnComplete:Boolean;
		public function set destroyOnComplete(value:Boolean):void	{ _destroyOnComplete = value; }
		protected var _autoBitmap:Boolean;
		protected var _subSceneEntity:Entity;
		//protected var _parentCutScene:CutScene;

		protected var _nextSubScene:CutSubScene;
		protected var _completeHandler:Function;
	}
}