package game.data.ui.card
{
	import game.data.ui.ButtonData;
	import game.util.DataUtils;

	public class CardRadioButtonData extends ButtonData
	{

		public function CardRadioButtonData( xml:XML = null ):void
		{
			super( xml );
			this.xPos = xPos;
			this.yPos = yPos;
		}

		protected override function parseXML( xml:XML ):void
		{
			super.parseXML( xml );

			if( xml.hasOwnProperty("color") )
			{
				this.color = int( DataUtils.getNumber( xml.color ) );
			}

			if( xml.hasOwnProperty("val") )
			{
				var valString:String = DataUtils.getString(xml.val);

				if(isNaN(Number(valString)))
					this.value = valString;
				else
					this.value = int(valString);
			}

			if(xml.hasOwnProperty("alpha"))
			{
				this.alpha = DataUtils.getNumber(xml.alpha);
			}

			if(xml.hasOwnProperty("x"))
			{
				this.xPos = DataUtils.getNumber(xml.x);
			}

			if(xml.hasOwnProperty("y"))
			{
				this.yPos = DataUtils.getNumber(xml.y);
			}
		}

		public var color:int;
		public var xPos:Number;
		public var yPos:Number;
		public var alpha:Number;
	}
}
