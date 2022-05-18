package game.scenes.prison.yard.states
{
	import engine.components.Audio;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.data.sound.SoundModifier;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullSittingAngryState extends MovieclipState
	{
		public function SeagullSittingAngryState()
		{
			this.type = "sitAngry";
		}
		
		override public function start():void
		{
			this.setLabel("angrynest");
			_angryNum = 0;
			
			Audio(node.entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "seagull_squawk_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);			
			node.timeline.handleLabel("endanger", Command.create(node.fsmControl.setState, MovieclipState.STAND));
		}
		
		private var _angryNum:int;
	}
}