package game.scenes.survival1.crashLanding
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.timeline.Timeline;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Tremble;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CutScene;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.woods.Woods;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class CrashLanding extends CutScene
	{
		public function CrashLanding()
		{
			super();
			configData("scenes/survival1/crashLanding/", Survival1Events(events).CRASH_LANDING);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			SceneUtil.removeIslandParts(this);
			super.init(container);
		}
		
		override public function load():void
		{
			if(shellApi.checkEvent(completeEvent))
			{
				shellApi.loadScene(Woods);
				return
			}
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
		
		override public function setUpCharacters():void
		{
			var sequence:AnimationSequence = new AnimationSequence(Grief, Grief);
			sequence.add( new AnimationData( Tremble, 60 ) );
			sequence.add( new AnimationData( Grief ) );
			sequence.loop = true;
			
			var animControl:AnimationControl = player.get(AnimationControl);
			var animEntity:Entity = animControl.getEntityAt();
			var animSequencer:AnimationSequencer = animEntity.get(AnimationSequencer);
			
//			var motion:Motion = player.get( Motion );
//			motion.maxVelocity.y = 0;
			// remove his motion and let's see if he still falls
			player.remove( Motion );
			
			if(animSequencer == null)
			{
				animSequencer = new AnimationSequencer();
				animEntity.add(animSequencer);
			}
			
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
			
			setEntityContainer(player, screen.blimp.player_container);
			
			Timeline( player.get(Timeline) ).labelReached.add( onAnimEnd );
			
			start();
		}
		
		private function onAnimEnd( label:String ):void
		{
			if( label == "ending" )
			{
				var spatial :Spatial = player.get(Spatial);
				spatial.scaleX *= -1;
			}
		}
		
		override public function onLabelReached(label:String):void
		{
			if( label == "gotHit" )
			{
				shellApi.completeEvent(completeEvent);
				CharUtils.getTimeline( player ).labelReached.remove(onAnimEnd);
				removeEntity( player );
				removeGroup( super.getGroupById( CharacterGroup.GROUP_ID ), true );
			}
			if(label.indexOf("lightning") > -1)
				shellApi.triggerEvent("lightning");
			if(label == "surge")
				shellApi.triggerEvent("surge");
		}
		
		override public function end():void
		{
			super.end();
			shellApi.loadScene( Woods, 850, 443, "right" );
		}
	}
}