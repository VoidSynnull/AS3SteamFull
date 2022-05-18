package game.scenes.myth.labyrinthSnake.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.managers.EntityPool;
	import game.scenes.myth.labyrinthSnake.components.SnakeComponent;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import nape.callbacks.InteractionType;
	
	import org.osflash.signals.Signal;
	
	
	public class Snake extends Popup
	{
		public function Snake( container:DisplayObjectContainer=null )
		{
			super(container);
		}
		
		override public function destroy():void
		{
			_pool = null;
			_total = null;
			
			complete.removeAll();
			complete = null;
			
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			complete = new Signal();
			
			_pool = new EntityPool();
			_pool.setSize( "normSnake", 13 );
			_pool.setSize( "targSnake", 1 );
			_total = new Dictionary();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/labyrinthSnake/";
			super.init( container );
			
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "snake.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "snake.swf", true ) as MovieClip;
			
			this.layout.centerUI( super.screen.content );
			loadCloseButton();
			
			createSnakeHoles();
			createSnakes();
			
			super.loaded();
		}
		
		private function createSnakeHoles():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var number:int; 
				
			for( number = 0; number < 13; number ++ )
			{
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "l" + number ));
				entity = EntityUtils.createSpatialEntity( this, clip, super.screen.content );
				entity.add( new Id( "hole" + number ));
			}
		}
		
		private function createSnakes():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var number:int; 
			
			for( number = 0; number < 13; number ++ )
			{
				clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "normSnake" + number ));
				loadSnakes( clip, "normSnake" );
			}
			clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "targSnake" ));
			loadSnakes( clip, "targSnake" );
			
			spawnSnakes();
		}
		
		private function loadSnakes( asset:MovieClip, type:String ):void
		{
			var entity:Entity;
			var clip:MovieClip;
			var hole:Entity;
			var timeline:Timeline;
			var interaction:Interaction;
			
			entity = EntityUtils.createSpatialEntity( this, asset, super.screen.content );
			entity.add( new Id( type ));
			
			TimelineUtils.convertClip( asset, this, entity );
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.DOWN ]);
			interaction = entity.get( Interaction );
			interaction.downNative.add( Command.create( caughtSnake, entity ));
			
			ToolTipCreator.addToEntity( entity );
			
			Sleep( entity.get( Sleep )).ignoreOffscreenSleep = true;
			_pool.release( entity, type );
		}
		
		private function spawnSnakes():void
		{
			var entity:Entity;
			var hole:Entity;
			var holeNumber:int;
			var number:int;
			var timeline:Timeline;
			var type:String;
			var sleep:Sleep;
			
		
			if( snakeComponent.state == snakeComponent.SPAWN )
			{
				if( _total[ "targSnake" ] == 1 )
				{
					type = "normSnake";	
					snakeComponent.activeNormal++;
				}
					
				else
				{
					number = Math.round( Math.random());
					switch( number )
					{
						case 0:
							type = "normSnake";
							snakeComponent.activeNormal++;
							break;
						case 1:
							type = "targSnake";
							snakeComponent.activeTarget++;
							break;
					}
				}
				
				// grab an entity and hole
				entity = _pool.request( type );
				if( !_total[ type ]) 
				{
					_total[ type ] = 0;
				}
				_total[ type ]++;
				snakeComponent.activeSnakes++;
				
				var isOpen:Boolean;
				
				// find an empty hole
				do
				{
					isOpen = true;
					holeNumber = Math.round( Math.random() * 12 );
					
					if( snakeComponent.activeHoles[ holeNumber ] == true )
					{
						isOpen = false;
					}
				}
				while( !isOpen );
				
				snakeComponent.activeHoles[ holeNumber ] = true;
				
				
				hole = super.getEntityById( "hole" + holeNumber );
				
				if( entity != null )
				{
					sleep = entity.get(Sleep);
					timeline = entity.get( Timeline );
					
					sleep.sleeping = false;
					entity.ignoreGroupPause = false;
					sleep.ignoreOffscreenSleep = true;
					
					EntityUtils.positionByEntity( entity, hole );
					timeline.gotoAndPlay( "intro" );
					// reset label handler to have new hole number for tracking
					timeline.labelReached.add( Command.create( snakeHandler, entity, type, holeNumber ));
				}
				
				if( snakeComponent.activeSnakes < snakeComponent.maxSnakes )
				{
					spawnSnakes();
				}
			}
			else
			{
				if( snakeComponent.activeSnakes == 0 )
				{
					SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, completeSnake ));
				}
			}
		}
		
		private function snakeHandler( label:String, entity:Entity, type:String, holeNumber:Number ):void
		{
			var timeline:Timeline = entity.get( Timeline );
			var sleep:Sleep = entity.get(Sleep);
			var random:Number = Math.random( ) * 3;
			var tempVector:Vector.<Number> = new Vector.<Number>;
			var loop:int;
			var toolTip:ToolTip;
			var spatial:Spatial = entity.get( Spatial );
	
			switch( label )
			{
				case "endIntro":
					
					if( Math.random() * 10 > 8 )
					{
						super.shellApi.triggerEvent( "snake_hiss" );
					}
					
					toolTip = new ToolTip();
					toolTip.type = "click";
					entity.add( toolTip );
					break;
				
				case "endIdle":
					
					if( random > 2 )
					{
						timeline.gotoAndPlay( "idle" );
					}
					
					else
					{
						if( Math.random() * 10 > 8 )
						{
							super.shellApi.triggerEvent( "snake_hiss" );
						}
						
						timeline.gotoAndPlay( "outro" );
						entity.remove( ToolTip );
					}
					
					break;
				
				case "endCatch":
					
					if( snakeComponent.snakesCaught >= 3 )
					{
						snakeComponent.state = snakeComponent.VICTORY;
						super.closeClicked.removeAll();
						super.removeEntity(super.closeButton);
						
						SceneUtil.lockInput( this );
					}
					
					break;
				
				case "endOutro":
					if( _pool.release( entity, type ))
					{
						sleep.sleeping = true;
						entity.ignoreGroupPause = true;
					
						_total[ type ]--;
						
						timeline.labelReached.removeAll();
						switch( type )
						{
							case "targSnake":
								snakeComponent.activeTarget--;
								break;
							case "normSnake":
								snakeComponent.activeNormal--;
								break;
						}
						
						snakeComponent.activeSnakes--;
						snakeComponent.activeHoles[ holeNumber ] = false;
						spawnSnakes();
					}
					break;
			}
		}
		
		private function caughtSnake( e:Event, entity:Entity ):void
		{
			var timeline:Timeline = entity.get( Timeline );
			var timelineClip:TimelineClip = entity.get( TimelineClip );
			var type:String = entity.get( Id ).id;
			
			if( timelineClip.mc.currentLabel == "idle" )
			{
				// if you catch a red-eyed snake, add 3 more to the rotation
				if( type == "targSnake" )
				{
					snakeComponent.snakesCaught++;
					snakeComponent.maxSnakes = snakeComponent.snakesCaught * 3 + 3;
					super.shellApi.triggerEvent( "right_snake" );
				}
				
				else
				{
					super.shellApi.triggerEvent( "wrong_snake" );
				}
				timeline.gotoAndPlay( "catch" );
			}
		}
		
		private function completeSnake():void
		{
			complete.dispatch();
		}
		
		public var complete:Signal;
		public var snakeComponent:SnakeComponent = new SnakeComponent();
		private var _pool:EntityPool;
		private var _total:Dictionary;
	}
}