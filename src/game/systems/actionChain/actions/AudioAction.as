package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.AudioUtils;

	/**
	 * Plays audio file from sounds folder
	 */
	public class AudioAction extends ActionCommand {
		private var target:Entity;
		private var soundUrl:String;
		private var radius:Number;
		private var minVolume:Number;
		private var maxVolume:Number;
		private var ease:Function;
		private var loop:Boolean;
		private var group:Group;
		private var stopMusicEffect:Boolean;
		private var audioId:String;
		/**
		 * audio action 
		 * @param radius, if no radius provided, audio will play as global sound
		 */
		public function AudioAction(target:Entity, soundUrl:String, radius:Number = 500, minVolume:Number = 0, maxVolume:Number = 1,
									ease:Function = null, loop:Boolean = false,stopMusicEffect:Boolean=false,audioId:String = null) 
		{
			// need to preload sound here?
			this.target 	= target;
			this.soundUrl 	= soundUrl;
			this.radius 	= radius;
			this.minVolume 	= minVolume;
			this.maxVolume 	= maxVolume;
			this.ease 		= ease;
			this.loop 		= loop;
			this.stopMusicEffect    = stopMusicEffect;
			this.audioId 			= audioId;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			this.group = group;
			
			var audio:Audio;
			if(target)
				audio = target.get(Audio);
			
			if(audio && stopMusicEffect && audio.isPlaying( soundUrl))	
			{
				audio.stop(soundUrl);
			}
			else
			{
				// if soundUrl is comma-delimited string, then randomize them but don't play the some one in a row
				if (soundUrl.indexOf(",") != -1)
				{
					var arr:Array = soundUrl.split(",");
					while (true)
					{
						var random:int = Math.floor(arr.length * Math.random());
						// if previous random not set or previous random doesn't match
						if ((node.optional.length == 1) || (node.optional[1] != random))
						{
							node.optional[1] = random;
							break;
						}
					}
					node.optional.push(random);
					soundUrl = arr[random];
				}
				
				if( radius == 0 )
					AudioUtils.play( group, soundUrl, maxVolume, loop, null, null, maxVolume );
				else
					AudioUtils.playSoundFromEntity( target, soundUrl, radius, minVolume, maxVolume, ease, loop );
			}
			if( callback )
				callback();
		}
		
		override public function cancel():void 
		{
			AudioUtils.stop( group, soundUrl );
		}
	}
}