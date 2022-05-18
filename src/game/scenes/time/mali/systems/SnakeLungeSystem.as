package game.scenes.time.mali.systems
{
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.audio.HitAudio;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.Hazard;
	import game.scenes.time.TimeEvents;
	import game.data.scene.hit.HitAudioData;
	import game.scenes.time.mali.components.SnakeLunge;
	import game.scenes.time.mali.nodes.SnakeLungeNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;

	
	public class SnakeLungeSystem extends GameSystem
	{
		public function SnakeLungeSystem()
		{
			super(SnakeLungeNode, updateNode);
		}
		public override function addToEngine(engine:Engine):void
		{
			super.addToEngine(engine);
		}
		
		private function updateNode(node:SnakeLungeNode, time:Number):void
		{
			var snakeLunge:SnakeLunge = node.snakeLunge;
			// locate player, turn snake towards them
			var player:Entity = super.group.shellApi.player;
			var charSpatial:Spatial = player.get( Spatial );
			
			var delX:Number = charSpatial.x - snakeLunge.strikeSpace.x;
			if (delX < 0) {
				node.entity.get(TimelineClip).mc.scaleX = -1;
			}
			else {
				node.entity.get(TimelineClip).mc.scaleX = 1;
			}
			// lunge
			if (!snakeLunge.lunging && Math.abs(delX) < LUNGE_RANGE && charSpatial.y<=snakeLunge.strikeSpace.y && charSpatial.y>=snakeLunge.strikeSpace.y - LUNGE_RANGE/2) {
				node.entity.get(Timeline).gotoAndPlay("strike");
				node.entity.get(Timeline).handleLabel("strikeSound",Command.create(endLunge,snakeLunge));
				hitPlayer(node,player);
				playLungeSound(snakeLunge);
			}
		}
		
		// create a forced hazard impact on player
		private function hitPlayer(node:SnakeLungeNode, player:Entity):void
		{
			var snakeHit:Entity = node.snakeLunge.snakeHit;
			var hazard:Hazard = snakeHit.get(Hazard);
			var hazardCollider:HazardCollider = player.get(HazardCollider);
			if(snakeHit.get(Display).displayObject.x > player.get(Motion).x)		// determine direction of knockback
			{
				hazardCollider.velocity.x = -hazard.velocity.x;
			}
			else
			{
				hazardCollider.velocity.x = hazard.velocity.x;
			}
			hazardCollider.velocity.y = -hazard.velocity.y;
			hazardCollider.isHit = true;
			player.get(CurrentHit).hit = snakeHit;
			EntityUtils.playAudioAction(player.get(HitAudio), snakeHit.get(HitAudioData));
			hazardCollider.coolDown = hazard.coolDown;
			hazardCollider.interval = hazard.interval;
		}
		
		private function endLunge(snake:SnakeLunge):void
		{
			snake.lunging = false;
		}
		
		private function playLungeSound(snake:SnakeLunge):void
		{
			snake.lunging = true;
			var shellApi:ShellApi = this.group.shellApi;
			var events:TimeEvents = TimeEvents(shellApi.sceneManager.currentScene.events);
			shellApi.triggerEvent(events.SNAKE_BITE, true);
		}
		private const LUNGE_RANGE:Number = 200;
	}
}