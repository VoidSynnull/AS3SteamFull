package game.scenes.deepDive3.shared.groups
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.sound.SoundModifier;
	import game.scenes.deepDive1.shared.SubScene;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.PerformanceUtils;
	
	public class LifeSupportGroup extends Group
	{
		public function LifeSupportGroup(scene:SubScene)
		{
			_scene = scene;
		}
		
		override public function destroy():void
		{
			_scene = null;
			super.destroy();
		}
		
		public function pipesOff( container:DisplayObjectContainer, pipeId:String = "lsPipe", startIndex:int = 1):void
		{
			var clip:MovieClip;
			var i:int = startIndex;
			for (i; container[pipeId+i] != null; i++)
			{
				clip = container[pipeId+i];
				clip.visible = false;
				clip.gotoAndStop(1);
			}
		}
		
		public function pipesRemove( container:DisplayObjectContainer, pipeId:String = "lsPipe", startIndex:int = 1):void
		{
			var i:int = startIndex;
			for (i; container[pipeId+i] != null; i++)
			{
				container.removeChild( container[pipeId+i] );
			}
		}
		
		public function activatePipes( container:DisplayObjectContainer, foregroundContainer:DisplayObjectContainer = null, pipeId:String = "lsPipe", startIndex:int = 1):void
		{
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			_scene.addSystem( new TimelineVariableSystem() );
			var frameRate:int = 16;

			var pipeEntity:Entity;
			var clip:MovieClip;
			var i:int = startIndex;
			var bitmapSequence:BitmapSequence;

			for (i; container[pipeId+i] != null; i++)
			{
				clip = container[pipeId+i];
				clip.visible = true;
				if( foregroundContainer != null )
				{
					foregroundContainer.addChild(clip);
				}
				
				// convert to bitmap sequence (share sequence across pipes)
				if( bitmapSequence == null )
				{	
					clip.gotoAndStop(1)
					pipeEntity = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, null, bitmapQuality, frameRate);
					bitmapSequence = pipeEntity.get( BitmapSequence );
				}
				else
				{
					pipeEntity = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, bitmapSequence, bitmapQuality, frameRate);
				}
	
				Timeline( pipeEntity.get(Timeline) ).gotoAndPlay("on");
				pipeEntity.add(new Id(pipeId+i));
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "biopipe_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
				pipeEntity.add(audio);
				pipeEntity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
				_scene.addEntity( pipeEntity );
			}
		}

		private var _scene:SubScene;
	}
}