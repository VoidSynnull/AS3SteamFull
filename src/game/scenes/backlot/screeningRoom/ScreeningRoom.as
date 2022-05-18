package game.scenes.backlot.screeningRoom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.NetStatusEvent;
	import flash.geom.Point;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class ScreeningRoom extends PlatformerGameScene
	{
		public function ScreeningRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/screeningRoom/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			
			
			super.loaded();
		}
		
		private var backlot:BacklotEvents;
		private var finalMovie:MovieClip;
		
		private const flv:String = ".flv";
		private var movieNumber:int = 0;
		private var movieUrl:String;
		
		private var _videoFile:String;
		private var _videoPlayer:Video;
		private var _connection:NetConnection;
		private var _stream:NetStream;
		
		// all assets ready
		override public function loaded():void
		{
			backlot = events as BacklotEvents;
			super.loaded();
			setUpNpcs();
			setUpProjector();
			if(!shellApi.checkEvent(backlot.SAW_MOVIE))
			{
				SceneUtil.lockInput(this);
				SceneUtil.setCameraTarget(this, getEntityById("char10"));
				Dialog(getEntityById("char10").get(Dialog)).sayById("opening");
			}
			shellApi.eventTriggered.add(onEventTriggered);
		}
		
		private function setUpProjector():void
		{
			var projector:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["projection"],_hitContainer);
			projector.add(new Id("projector"));
			projector.add(new SceneInteraction());
			InteractionCreator.addToEntity(projector,[InteractionCreator.CLICK],_hitContainer["projection"]);
			SceneInteraction(projector.get(SceneInteraction)).reached.add(bigNight);
			ToolTipCreator.addToEntity(projector);
			Display(projector.get(Display)).alpha = 0;
			
			super.loadFile("finalMovie.swf",loadMoviePlayer);
			
			_connection = new NetConnection();
			_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			_connection.connect(null);
		}
		
		private function bigNight(player:Entity, entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("big premiere");
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if(event == backlot.NO_GOOD_MOVIES)
			{
				SceneUtil.setCameraTarget(this, getEntityById("char11"));
			}
			if(event == backlot.NO_MOVIES)
			{
				SceneUtil.setCameraTarget(this, getEntityById("char12"));
			}
			if(event == backlot.FREE_POPCORN)
			{
				SceneUtil.lockInput(this, false);
				SceneUtil.setCameraTarget(this, player);
			}
			if(event == backlot.REELS)
			{
				if(checkIfNearProjector())
				{
					var projector:Entity = getEntityById("projector");
					CharUtils.moveToTarget(player, projector.get(Spatial).x, projector.get(Spatial).y,false,startMovie);
				}
				else
				{
					Dialog(player.get(Dialog)).sayById("not here");
				}
			}
			if(event == backlot.WATCH_NEXT_MOVIE)
			{
				SceneUtil.setCameraTarget(this, player);
				loadNextMovie();
			}
		}
		
		private function startMovie(player:Entity):void
		{
			trace("start movie sequence");
			SceneUtil.lockInput(this);
			setUpFade();
		}
		
		private function setUpFade():void// start determines if you should start the acting sequence(true) or go back to the dressing room (false)
		{
			var darkFade:Entity = EntityUtils.createSpatialEntity(this, new MovieClip(),this.overlayContainer);
			darkFade.add(new Id("darkFade"));
			var darkFadeDisplay:Display = darkFade.get(Display);
			//darkFadeDisplay.moveToBack();
			var left:Number = -super.shellApi.camera.camera.viewport.width /2 - 100;
			var width:Number = super.shellApi.camera.camera.viewport.width + 200;
			var top:Number = -super.shellApi.camera.camera.viewport.height /2 - 300;
			var height:Number = super.shellApi.camera.camera.viewport.height + 200;
			var display:MovieClip = darkFadeDisplay.displayObject as MovieClip;
			display.graphics.beginFill(0);
			display.graphics.moveTo( left, top);
			display.graphics.lineTo(width, top);
			display.graphics.lineTo(width, height);
			display.graphics.lineTo( left, height);
			display.graphics.endFill();
			display.alpha =0;
			darkFadeDisplay.alpha = 0;
			var position:Spatial = darkFade.get(Spatial);
			position.x = 0;
			position.y = 0;
			
			SceneUtil.addTimedEvent(super, new TimedEvent(.1,12,Command.create(fade,1)));
		}
		
		private function fade(fadeDirection:int = 1):void
		{
			var darkFade:Display = getEntityById("darkFade").get(Display);
			
			trace(darkFade.alpha);
			
			if(darkFade.alpha > .5)// this is when the screen goes black
			{
				darkFade.alpha = .5;
				loadNextMovie();
				return;
			}
			///*
			if(darkFade.alpha < 0)// this is when the screen goes black
			{
				removeEntity(getEntityById("darkFade"));
				return;
			}
			//*/
			darkFade.alpha += .05 * fadeDirection;
		}
		
		private function afterMovie():void
		{
			//Display(getEntityById("darkFade").get(Display)).moveToBack();
			trace("comments after movie " + movieNumber);
			var character:Entity;
			switch(movieNumber)
			{
				case 1:
				{
					character = getEntityById("char1");
					SceneUtil.setCameraTarget(this, character);
					Dialog(character.get(Dialog)).sayById("after_movie_1");
					break;
				}
				case 2:
				{
					character = getEntityById("char3");
					SceneUtil.setCameraTarget(this, character);
					Dialog(character.get(Dialog)).sayById("after_movie_2");
					break;
				}
				case 3:
				{
					character = getEntityById("char7");
					SceneUtil.setCameraTarget(this, character);
					Dialog(character.get(Dialog)).sayById("after_movie_3");
					break;
				}
				case 4:
				{
					character = getEntityById("char5");
					SceneUtil.setCameraTarget(this, character);
					Dialog(character.get(Dialog)).sayById("after_movie_4");
					exitTheatre1();
					break;
				}
			}
		}
		
		private function exitTheatre1():void
		{
			removeEntity(getEntityById("char1"));
			removeEntity(getEntityById("char2"));
			removeEntity(getEntityById("char10"));
			removeEntity(getEntityById("char11"));
			removeEntity(getEntityById("char12"));
			
			for(var i:int = 3; i < 9; i++)
			{
				if(i == 5 || i == 6)
					continue;
				var char:Entity = getEntityById("char"+i);
				CharUtils.setAnim(char, Stand);
				CharUtils.moveToTarget(char,225,675,false,exitTheatre);
				CharacterMotionControl(char.get(CharacterMotionControl)).maxVelocityX = 200;
			}
		}
		
		private function exitTheatre2():void
		{
			removeEntity(getEntityById("char5"));
			removeEntity(getEntityById("char6"));
			removeEntity(getEntityById("char9"));
		}
		
		private function exitTheatre(char:Entity):void
		{
			removeEntity(char);
		}
		
		private function loadNextMovie():void
		{
			movieNumber++;
			if(movieNumber <= 4)
			{
				SceneUtil.addTimedEvent(super, new TimedEvent(1,1,fnConnectStream));
			}
			else
			{
				shellApi.triggerEvent(backlot.SAW_MOVIE, true);
				shellApi.removeItem(backlot.REELS);
				SceneUtil.lockInput(this, false);
				SceneUtil.addTimedEvent(super, new TimedEvent(.1,12,Command.create(fade,-1)));
				SceneUtil.addTimedEvent(super, new TimedEvent(.1,1,exitTheatre2));
			}
		}
		
		private function loadMoviePlayer(asset:*):void
		{
			finalMovie = asset as MovieClip;
			finalMovie.scaleX = shellApi.camera.camera.viewportWidth / 640;
			finalMovie.scaleY = shellApi.camera.camera.viewportHeight / 480;
			_videoPlayer = finalMovie.finalMovie;
			var movie:Entity = EntityUtils.createSpatialEntity(this, finalMovie, overlayContainer);
			movie.add(new Id("movie"));
			Display(movie.get(Display)).visible = false;
		}
		
		private function fnStatus(aEvent:NetStatusEvent):void
		{
			switch (aEvent.info.code) {
				case "NetConnection.Connect.Success":
					trace("successful connection, now connect stream");
					//fnConnectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					// video not found
					trace("Ad Video Player: Unable to locate video");
					break;
				case "NetStream.Play.Stop":
					// video reaches end
					endVideo();
					break;
			}
		}
		
		private function endVideo():void
		{
			trace(getEntityById("movie"));
			Display(getEntityById("movie").get(Display)).visible = false;
			
			afterMovie();
		}
		
		private function fnConnectStream():void
		{
			// set up stream
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			
			// set buffer to 0.1 seconds
			_stream.bufferTime = 0.1;
			
			// metadata
			var vMetaData:Object=new Object();
			//vMetaData.onMetaData = fnMetaData;
			_stream.client = vMetaData;
			
			// setup video and stream
			
			_videoPlayer.attachNetStream(_stream);
			
			// determine location of video
			_videoFile = super.shellApi.assetPrefix + "scenes/backlot/screeningRoom/finalMovie";
			movieUrl = _videoFile + movieNumber + flv;
			
			_stream.play(movieUrl);
			Display(getEntityById("movie").get(Display)).visible = true;
		}
		
		private function checkIfNearProjector():Boolean
		{
			var minDistance:Number = 500;
			var playerPos:Point = new Point(player.get(Spatial).x, player.get(Spatial).y);
			var projector:Entity = getEntityById("projector");
			var projectorPos:Point = new Point(projector.get(Spatial).x, projector.get(Spatial).y);
			
			if(Point.distance(playerPos, projectorPos) < minDistance)
				return true;
			
			return false;
		}
		
		private function setUpNpcs():void
		{
			for(var i:int = 1; i <= 12; i ++)
			{
				var char:Entity = getEntityById("char"+i);
				if(shellApi.checkEvent(backlot.SAW_MOVIE))
				{
					removeEntity(char);
					continue;
				}
				Display(char.get(Display)).moveToBack();
				Dialog(char.get(Dialog)).faceSpeaker = false;
				if(i >= 10)
				{
					//char.remove(SceneInteraction);
					// need to make it so they say their dialog with out moving to them
					// just by clicking on them
				}
			}
		}
	}
}