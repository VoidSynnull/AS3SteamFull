package game.data.scene.hit
{
	import game.util.DataUtils;

	public class BounceWireParser
	{
		public function parse(xml:XML):BounceWireHitData
		{
			var data:BounceWireHitData = new BounceWireHitData();
			
			data.hitChild = DataUtils.getString(xml.hitChild);
			data.radius = DataUtils.getNumber(xml.radius);
			
			if(xml.hasOwnProperty("lineColor"))
			{
				data.lineColor = DataUtils.getUint(xml.lineColor);
			}
			else
			{
				data.lineColor = 0x000000;
			}
			
			if(xml.hasOwnProperty("lineSize"))
			{
				data.lineSize = DataUtils.getNumber(xml.lineSize);
			}
			else
			{
				data.lineSize = 3;
			}
			
			if(xml.hasOwnProperty("tension"))
			{
				data.tension = DataUtils.getNumber(xml.tension);
			}
			else
			{
				data.tension = .5;
			}
			
			if(xml.hasOwnProperty("dampening"))
			{
				data.dampening = DataUtils.getNumber(xml.dampening);
			}
			
			return data;
		}
	}
}