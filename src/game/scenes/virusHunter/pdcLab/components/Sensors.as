package game.scenes.virusHunter.pdcLab.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class Sensors extends Component
	{
		public var sensors:Vector.<Entity>; // sensorMC and sensorTargetMC pairs
		public var trackedEntities:Vector.<Entity>; // vector of entities to be sensed
		
		public function Sensors($sensors:Vector.<Entity>, $trackedEntities:Vector.<Entity>){
			sensors = $sensors;
			trackedEntities = $trackedEntities;
		}
	}
}