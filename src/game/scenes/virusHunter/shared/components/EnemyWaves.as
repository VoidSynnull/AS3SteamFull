package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	import game.scenes.virusHunter.shared.data.EnemyWaveData;
	
	import org.osflash.signals.Signal;
	
	public class EnemyWaves extends Component
	{
		public function EnemyWaves()
		{
			allWavesDestroyed = new Signal();
			waveDestroyed = new Signal(Number);
			reachedBoss = new Signal();
		}
				
		public var allDestroyed:Boolean = false;
		public var waves:Vector.<EnemyWaveData>;
		public var waveIndex:int = 0;
		public var groupIndex:int = 0;
		public var allWavesDestroyed:Signal;
		public var waveDestroyed:Signal;
		public var reachedBoss:Signal;
		public var pauseWaveCreation:Boolean = false;
		public var pauseBossCreation:Boolean = true;
		public var pauseAfterWaveDestroyed:Boolean = true;
		public var pauseBeforeBossCreation:Boolean = true;
	}
}