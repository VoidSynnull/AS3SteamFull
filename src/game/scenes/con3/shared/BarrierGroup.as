package game.scenes.con3.shared
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Children;
	import game.components.hit.Wall;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scene.template.AudioGroup;
	import game.scenes.con3.Con3Events;
	import game.scenes.con3.shared.particles.ArrowExplosion;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class BarrierGroup extends Group
	{
		public function BarrierGroup()
		{
			super();
		}
		
		private var _barrierCasingSequence:BitmapSequence;
		private var _barrierBeamSequence:BitmapSequence;
		private var _fuseSequence:BitmapSequence;
		
		
		private var _audioGroup:AudioGroup;
		private var _container:DisplayObjectContainer;
		private var _events:Con3Events;
		private var _group:Scene;
		
		private const IDLE:String					= "idle";
		private const TRIGGER:String				= "trigger";
		
		private const BARRIER:String				= "barrier";
		private const FUSE:String					= "fuse";
		private const TARGET:String					= "target";
		
		private const CASE:String					= "_case";
		private const SHIELD:String					= "_shield";
		
		override public function destroy():void
		{
			if( _barrierCasingSequence )
			{
				_barrierCasingSequence.destroy();
				_barrierCasingSequence = null;
			}
			if( _barrierBeamSequence )
			{
				_barrierBeamSequence.destroy();
				_barrierBeamSequence = null;
			}
			if( !_fuseSequence )
			{
				_fuseSequence.destroy();
				_fuseSequence = null;
			}
			super.destroy();
		}
		
		/**
		 * BARRIERS
		 */
		public function createBarriers( group:Scene, container:DisplayObjectContainer ):void
		{
			// TODO link up bow-and-arrow stuff
			_audioGroup = group.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_container = container;
			_group = group;
			_events = new Con3Events();
			
			var beam:Entity;
			var casing:Entity;
			var child:DisplayObject;
			var children:Children;
			var clip:MovieClip;
			var explode:ArrowExplosion;
			var fuse:Entity;
			var number:String;
			var sig:WrappedSignal;
			var target:Entity;
			var wall:Entity;
			
			for each( child in container )
			{
				if( child.name.indexOf( BARRIER ) > -1 && child.name.length < 9 )
				{
					// BARRIER BEAM
					clip = child as MovieClip;
					number = clip.name.substr( clip.name.length - 1 );
					if( !_barrierBeamSequence )
					{
						_barrierBeamSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
					}
					beam = makeTimeline( clip, true, _barrierBeamSequence );
					beam.add( new Id( clip.name ));
					
					// BARRIER OUTER CASE
					clip = container[ BARRIER + number + CASE ];
					if( !_barrierCasingSequence )
					{
						_barrierCasingSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
					}
					casing = makeTimeline( clip, false, _barrierCasingSequence );
					casing.add( new Id( clip.name ));
					
					clip = container[ BARRIER + number + SHIELD ];
					wall = EntityUtils.createSpatialEntity( this, clip );
					wall.add( new Wall());
					wall.add( new Id( clip.name ));
					
					children = new Children();
					children.children.push( beam, wall );
					casing.add( children );
					
					if( shellApi.checkEvent( _events.FUSE_DESTROYED_ + ( number )))
					{
						Timeline( beam.get( Timeline )).gotoAndStop( "off" );
						Timeline( casing.get( Timeline )).gotoAndStop( "off" );
						removeEntity( wall );
					}
					else
					{
						beam.add( new AudioRange( 400 ));
						
						_audioGroup.addAudioToEntity( beam );
						Audio( beam.get( Audio )).playCurrentAction( IDLE );
					}
				}
				
				else if( child.name.indexOf( FUSE ) > -1 && child.name.length < 6 )
				{
					clip = child as MovieClip;
					number = clip.name.substr( clip.name.length - 1 );
					
					if( !_fuseSequence )
					{
						_fuseSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
					}
					fuse = makeTimeline( clip, false, _fuseSequence );
					fuse.add( new Id( clip.name ));	
					
					target = group.getEntityById( TARGET + number );
					
					if( shellApi.checkEvent( _events.FUSE_DESTROYED_ + ( number )))
					{
						Timeline( fuse.get( Timeline )).gotoAndStop( "end" );
					}
					else
					{
						if( target )
						{
							sig = new WrappedSignal();
							sig.signal.addOnce( Command.create( breakFuse, fuse, number ));
							target.add( sig );

							_audioGroup.addAudioToEntity( fuse );
						}
					}
					
					// prepare explosion particles
					explode = new ArrowExplosion();
					explode.init();
					EmitterCreator.create( this, _container, explode, 0, 0, fuse, "boom" + number, fuse.get( Spatial ), false );
				}
			}
		}
		
		private function makeTimeline( clip:MovieClip, play:Boolean = true, seq:BitmapSequence = null ):Entity
		{
			var target:Entity = EntityUtils.createMovingTimelineEntity( this, clip, null, play );
			target = BitmapTimelineCreator.convertToBitmapTimeline( target, clip, true, seq, PerformanceUtils.defaultBitmapQuality + 0.3);
		
			if( play && PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				Timeline( target.get( Timeline )).gotoAndStop( 1 );
			}
			return target;
		}
		
		private function breakFuse( wall:Entity, fuse:Entity, number:int ):void
		{
			Timeline( fuse.get( Timeline )).gotoAndPlay( "off" );
			ArrowExplosion( Emitter( getEntityById( "boom" + number ).get( Emitter )).emitter ).start();
			SceneUtil.setCameraTarget( _group, fuse );
			// TODO replace timer with explode effect
			
			var audio:Audio = fuse.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			SceneUtil.addTimedEvent( this , new TimedEvent( 1.6, 1, Command.create( breakBarrier, number )));
		}
		
		private function breakBarrier( number:int ):void
		{			
			var frame:Entity = getEntityById( BARRIER + number + CASE ); 
			SceneUtil.setCameraTarget( _group, frame );
			var children:Children = frame.get( Children );
			var beam:Entity = children.getChildByName( BARRIER + number );
			var wall:Entity  = children.getChildByName( BARRIER + number + SHIELD );
			
			var timeline:Timeline = frame.get( Timeline );
			timeline.gotoAndPlay( "turnOff" );
			
			timeline = beam.get( Timeline );
			timeline.gotoAndPlay( "turnOff" );
			timeline.handleLabel( "off", Command.create( unlock, beam ));
			wall.remove( Wall );
			
			Audio( beam.get( Audio )).playCurrentAction( TRIGGER );
			shellApi.completeEvent( _events.FUSE_DESTROYED_ + ( number ));
		}	
		
		private function unlock( beam:Entity = null ):void
		{
			SceneUtil.lockInput( _group, false );
			if( beam )
			{
				_group.removeEntity( beam, true );
			}
			SceneUtil.setCameraTarget( _group, _group.shellApi.player );
		}
	}
}