package game.scenes.con3.shared.power
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	public class PowerSystem extends System
	{
		private var _nodes:NodeList;
		private var _inputs:Array = [];
		
		public function PowerSystem()
		{
			super();
		}
		
		override public function update(time:Number):void
		{
			for(var node1:PowerNode = this._nodes.head; node1; node1 = node1.next)
			{
				if(node1.power._numSources)
				{
					node1.power._input = 0;
					
					this._inputs.length = 0;
					
					for(var node2:PowerNode = this._nodes.head; node2; node1 = node2.next)
					{
						if(node1.power._sources[node2.power._source])
						{
							this._inputs.push(node2.power._output);
						}
					}
					
					//Convert the outputs into input.
					node1.power._input = node1.power._inputConverter.convert(this._inputs, time);
					
					//Don't allow input to be NaN. Since that's impossible.
					if(isNaN(node1.power._input))
					{
						node1.power._input = 0;
					}
				}
				
				if(node1.power._input < node1.power._power)
				{
					node1.power._output = 0;
					
					if(node1.power._powered)
					{
						node1.power._powered = false;
						node1.power._off.dispatch(node1.entity);
					}
				}
				else if(node1.power._input >= node1.power._power)
				{
					//Convert the input into output.
					node1.power._output = node1.power._outputConverter.convert(node1.power._input, time);
					
					//Don't allow output to be NaN. Since that's impossible.
					if(isNaN(node1.power._output))
					{
						node1.power._output = 0;
					}
					
					if(!node1.power._powered)
					{
						node1.power._powered = true;
						node1.power._on.dispatch(node1.entity);
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._nodes = systemManager.getNodeList(PowerNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PowerNode);
			
			this._nodes = null;
		}
	}
}