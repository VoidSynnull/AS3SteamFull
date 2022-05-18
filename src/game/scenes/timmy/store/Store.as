package game.scenes.timmy.store
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.util.Command;
	
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.scenes.timmy.TimmyScene;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Store extends TimmyScene
	{
		private const DIG:String 							=	"dig";
		private const UP:String 							=	"up";
		private const DOWN:String 							=	"down";
		private const IN:String 							=	"in";
		private const OUT:String 							=	"out";
		
		private const SPIDER:String 						=	"spider";
		private const GROUNDHOG:String						=	"groundhog";
		private var _spiderSequence:BitmapSequence;
		private var _spiderTimer:TimedEvent;
		private var _groundhogSequence:BitmapSequence;
		private var _groundhogTimer:TimedEvent;
		
		override public function destroy():void
		{
			if( _spiderTimer )
			{
				_spiderTimer.stop();
				_spiderTimer								=	 null;
			}
			if( _groundhogTimer )
			{
				_groundhogTimer.stop();
				_groundhogTimer								=	 null;
			}
			if( _spiderSequence )
			{
				_spiderSequence.destroy();
				_spiderSequence 							=	null;
			}
			if( _groundhogSequence )
			{
				_groundhogSequence.destroy();
				_groundhogSequence 							=	null;
			}
			
			super.destroy();
		}
		
		public function Store()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/store/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupBook();
			setupAssets();
		}
		
		private function setupBook():void{
			var i:uint;
			for(i=1; i<=5; i++) {
				var entity:Entity = this.getEntityById("link"+i+"Interaction");
				
				var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(this.onLinkClicked);
			}
		}
		
		private function onLinkClicked(player:Entity, entity:Entity):void
		{
			switch(entity.get(Id).id) {
				case "link1Interaction":
					trace("TimmyStore");
					navigateToURL(new URLRequest("https://www.timmyfailure.com/" ), "_blank" );//new URLRequest("http://www.amazon.com/gp/product/0763680923/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0763680923&linkCode=as2&tag=poptropica-20&linkId=VXYIE5WTCWVT3FD2"), "_blank");
					break;
				case "link2Interaction":
					trace("Now Look What You've Done");
					navigateToURL(new URLRequest("https://www.amazon.com/gp/product/0763660515/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0763660515&linkCode=as2&tag=poptropica-20&linkId=7I3ZOQKOKZB44LRZ"), "_blank");
					break;
				case "link3Interaction":
					trace("Mistakes were made");
					navigateToURL(new URLRequest("https://www.amazon.com/gp/product/076366927X/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=076366927X&linkCode=as2&tag=poptropica-20&linkId=GYGKF2WK2LW2QOEE"), "_blank");
					break;
				case "link4Interaction":
					trace("We Meet Again");
					navigateToURL(new URLRequest("https://www.amazon.com/gp/product/0763673757/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0763673757&linkCode=as2&tag=poptropica-20&linkId=QXCDORQQW34PTCJJ"), "_blank");
					break;
				case "link5Interaction":
					trace("Sanitized for your protection");
					navigateToURL(new URLRequest("https://www.amazon.com/gp/product/0763680923/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=0763680923&linkCode=as2&tag=poptropica-20&linkId=VXYIE5WTCWVT3FD2"), "_blank");
					break;
			}
		}
		
		private function setupAssets():void
		{
			var clip:MovieClip 								=	_hitContainer[ SPIDER ];
			_spiderSequence 								=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			var entity:Entity 								=	makeEntity( clip, _spiderSequence, "up", true );
			var timeline:Timeline							=	entity.get( Timeline );
			timeline.labelReached.add( spiderHandler );
			_spiderTimer 									=	new TimedEvent( Math.random() * 3, 1, Command.create( advanceTimeline, entity ));
			SceneUtil.addTimedEvent( this, _spiderTimer, "spiderTimer" );
			
			
			clip 											=	_hitContainer[ GROUNDHOG ];
			_groundhogSequence 								=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			entity 											=	makeEntity( clip, _groundhogSequence, "dig1", true );
			timeline										=	entity.get( Timeline );
			timeline.labelReached.add( groundhogHandler );
			_groundhogTimer 								=	new TimedEvent( Math.random() * 3, 1, Command.create( advanceTimeline, entity ));
			SceneUtil.addTimedEvent( this, _groundhogTimer, "groundhogTimer" );
		}
		
		private function advanceTimeline( entity:Entity ):void
		{
			var timeline:Timeline 							=	entity.get( Timeline );
			timeline.play();
			
			if( Id( entity.get( Id )).id == SPIDER )
			{
				_spiderTimer 								=	new TimedEvent( Math.random() * 3, 1, Command.create( advanceTimeline, entity ));
				SceneUtil.addTimedEvent( this, _spiderTimer, "spiderTimer" );
			}
			else
			{
				_groundhogTimer 							=	new TimedEvent( Math.random() * 3, 1, Command.create( advanceTimeline, entity ));
				SceneUtil.addTimedEvent( this, _groundhogTimer, "groundhogTimer" );
			}
		}
		
		private function spiderHandler( event:String ):void
		{
			var entity:Entity 								=	getEntityById( SPIDER );
			var audio:Audio 								=	entity.get( Audio );
			
			if( event == UP || event == DOWN )
			{
				audio.playCurrentAction( TRIGGER );				
			}
		}
		
		private function groundhogHandler( event:String ):void
		{
			var entity:Entity 								=	getEntityById( GROUNDHOG );
			var audio:Audio 								=	entity.get( Audio );
			
			if( event.indexOf( DIG ) > -1 || event == OUT || event == IN )
			{
				audio.playCurrentAction( TRIGGER );				
			}
		}
	}
}



