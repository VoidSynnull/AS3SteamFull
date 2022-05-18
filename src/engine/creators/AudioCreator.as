package engine.creators
{
	import ash.core.Entity;
	import engine.components.Audio;

	public class AudioCreator
	{
		public function create():Audio
		{
			var audio:Audio = new Audio();
			audio.toPlay = new Vector.<AudioWrapper>();
			
			return(audio);
		}
	}
}