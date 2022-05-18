package game.scenes.shrink.schoolCafetorium
{	
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class SchoolCafetorium extends PlatformerGameScene
	{
		public function SchoolCafetorium()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/schoolCafetorium/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var shrinkRay:ShrinkEvents;
		
		private var timelines:Array = ["squid", "volcano", "rocket"];
		
		override protected function addBaseSystems():void
		{
			addSystem(new HitTheDeckSystem(), SystemPriorities.update);
			addSystem(new FollowClipInTimelineSystem(), SystemPriorities.update);
			super.addBaseSystems();
		}
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shrinkRay = events as ShrinkEvents;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpTimelines();
			setUpBalloon();
			setUpRocket();
			setUpCJExhibit();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == shrinkRay.GIVE_MEDALLION)
			{
				//shellApi.completedIsland();
				shellApi.getItem( shrinkRay.MEDALLION, null, true );
			}
			if( event == GameEvent.GOT_ITEM + shrinkRay.MEDALLION )
			{
				CharUtils.setAnim( player, Proud );
				var timeline:Timeline = player.get( Timeline );
				timeline.handleLabel( "ending", returnControl );
			}
		}
		
		private function returnControl():void
		{
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput( this, false );
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function setUpCJExhibit():void
		{
			var clip:MovieClip = _hitContainer["exhibit1"];
			BitmapUtils.convertContainer(clip);
			var exhibit:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			DisplayUtils.moveToBack(clip);
			TimelineUtils.convertClip(clip, this, exhibit, null, false);
			if( shellApi.checkEvent( shrinkRay.SHRUNK_SILVA ))
			{
				removeEntity( getEntityById( "char6" ));
				Timeline( exhibit.get( Timeline )).gotoAndStop( 1 );
				
				if( !shellApi.checkHasItem( shrinkRay.MEDALLION ))
				{
					SceneUtil.lockInput( this, true );
					Dialog( getEntityById( "cj" ).get( Dialog )).setCurrentById( "thanks" );
					Dialog( getEntityById( "char9" ).get( Dialog )).setCurrentById( "famous" );
					
					var spatial:Spatial = player.get( Spatial );
					spatial.x = 2200;
					spatial.y = 611;
					startTheDialog();
				}
			}
		}
		
		private function startTheDialog( ... args ):void
		{
			Dialog(getEntityById( "cj" ).get( Dialog )).sayById( "thanks" );	
		}
		
		private function setUpRocket():void
		{
			var entity:Entity = getEntityById("rocket");
			entity.remove(Sleep);
			var clip:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;
			clip.rocket.gotoAndStop("stand");
			
			var projectile:MovieClip = new MovieClip();
			
			var rocket:Entity = EntityUtils.createSpatialEntity(this, projectile, _hitContainer);
			rocket.add(new FollowClipInTimeline(clip.rocket, null, entity.get(Spatial)));
			
			setUpDuck(player, rocket);
			var char:Entity
			for(var i:int = 4; i < 9; i ++)
			{
				char = getEntityById("char"+i);
				setUpDuck(char, rocket);
			}
			char = getEntityById("cj");
			setUpDuck(char, rocket);
			
			var time:Timeline = entity.get(Timeline);
			time.handleLabel("ending", Command.create(removeRocket, entity, rocket));
			time.handleLabel("startRocket", Command.create(startRocket, entity));
			time.handleLabel("flying", youBetterDuck);
		}
		
		private function startRocket(rocket:Entity):void
		{
			var clip:MovieClip = Display(rocket.get(Display)).displayObject as MovieClip;
			clip.rocket.gotoAndPlay(1);
		}
		
		private function youBetterDuck():void
		{
			var char:Entity
			for(var i:int = 4; i < 9; i ++)
			{
				char = getEntityById("char"+i);
				if(char != null)
					HitTheDeck(char.get(HitTheDeck)).ignoreProjectile = false;
			}
			
			char = getEntityById("cj");
			if(char != null)
				HitTheDeck(char.get(HitTheDeck)).ignoreProjectile = false;
			
			HitTheDeck(player.get(HitTheDeck)).ignoreProjectile = false;
		}
		
		private function removeRocket(entity:Entity, rocket:Entity):void
		{
			removeEntity(entity, true);
			removeEntity(rocket, true);
		}
		
		private function setUpDuck(char:Entity, rocket:Entity):void
		{
			char.add(new HitTheDeck(rocket.get(Spatial),100));
			var hitTheDeck:HitTheDeck = char.get(HitTheDeck);
			hitTheDeck.duck.add(duck);
			hitTheDeck.coastClear.add(coastClear);
		}
		
		public function duck(char:Entity):void
		{
			CharUtils.setAnim(char, DuckDown);
		}
		
		public function coastClear(char:Entity):void
		{
			CharUtils.setAnim(char, Stand);
			if(char.get(FSMControl))
				FSMControl(char.get(FSMControl)).active = true;
		}
		
		private function setUpBalloon():void
		{
			var clip:MovieClip = _hitContainer[ "balloon" ];
			var balloon:Entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			balloon.add( new Id( "balloon" ));
			var interaction:Interaction = InteractionCreator.addToEntity( balloon, [InteractionCreator.CLICK]);
			interaction.click.add( clickBalloon );
			ToolTipCreator.addToEntity(balloon);
			Display( balloon.get( Display )).moveToBack();
			EntityUtils.createSpatialEntity( this, _hitContainer[ "balloonString" ]).add(new Id( "balloonString" ));
		}
		
		private function clickBalloon( entity:Entity ):void
		{
			var spatial:Spatial = entity.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			spatial.scale /= playerSpatial.scale;
			spatial.rotation = 360 * Math.random();
			Display( entity.get( Display )).setContainer( Display( player.get( Display )).displayObject );
			
			spatial = CharUtils.getPart( player, CharUtils.HEAD_PART ).get( Spatial );
			var follow:FollowTarget = new FollowTarget( spatial, .75 );
			follow.offset = new Point( -spatial.x, spatial.y + 30 );
			entity.add( follow );
			
			removeEntity( getEntityById( "balloonString" ));
		}
		
		private function setUpTimelines():void
		{
			for(var i:int = 0; i < timelines.length; i ++)
			{
				var clipName:String = timelines[i];
				var clip:MovieClip = _hitContainer[clipName];
				BitmapUtils.convertContainer(clip);
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				entity.add(new Id(clipName));
				TimelineUtils.convertClip(clip, this, entity, null, false);
				var time:Timeline = entity.get(Timeline);
				time.handleLabel("ending", Command.create(stopTime, time),false);
				
				var interaction:Interaction = InteractionCreator.addToEntity( entity, [InteractionCreator.CLICK]);
				interaction.click.add(clickTime);
				ToolTipCreator.addToEntity(entity);
				Display(entity.get(Display)).moveToBack();
			}
		}
		
		private function clickTime(entity:Entity):void
		{
			var interactionName:String = entity.get(Id).id;
			var time:Timeline = entity.get(Timeline);
			if(!time.playing)
			{
				shellApi.triggerEvent(interactionName);
				Timeline(entity.get(Timeline)).play();
			}
		}
		
		private function stopTime(timeline:Timeline):void
		{
			trace("stop");
			timeline.gotoAndStop(0);
		}
	}
}