part of mapbox_search_flutter;

class MapBoxPlaceSearchWidget extends StatefulWidget {
  MapBoxPlaceSearchWidget({
    @required this.apiKey,
    this.onSelected,
    // this.onSearch,
    this.fontSize,
    this.searchHint = 'Search',
    this.context,
    this.height,
    this.popOnSelect = false,
    this.location,
    this.country,
    this.icon,
    this.onIconTapped,
    this.onInputTapped,
  });

  /// True if there is different search screen and you want to pop screen on select
  final bool popOnSelect;

  ///To get the height of the page
  final BuildContext context;

  /// Height of whole search widget
  final double height;

  /// API Key of the MapBox.
  final String apiKey;

  /// The callback that is called when one Place is selected by the user.
  final void Function(MapBoxPlace place) onSelected;

  /// The callback that is called when the user taps on the search icon.
  // final void Function(MapBoxPlaces place) onSearch;

  /// The point around which you wish to retrieve place information.
  final Location location;

  ///Limits the search to the given country
  ///
  /// Check the full list of [supported countries](https://docs.mapbox.com/api/search/) for the MapBox API
  final String country;

  ///Search Hint Localization
  final String searchHint;

  ///Font Size
  final String fontSize;

  final Icon icon; //By R
  final void Function(String place) onIconTapped; //By R

  final void Function() onInputTapped; //By Nicolas

  @override
  _MapBoxPlaceSearchWidgetState createState() =>
      _MapBoxPlaceSearchWidgetState();
}

class _MapBoxPlaceSearchWidgetState extends State<MapBoxPlaceSearchWidget>
    with SingleTickerProviderStateMixin {
  TextEditingController _textEditingController = TextEditingController();
  AnimationController _animationController;

  // SearchContainer height.
  Animation _containerHeight;

  // Place options opacity.
  Animation _listOpacity;

  List<MapBoxPlace> _placePredictions = [];

  // MapBoxPlace _selectedPlace;

  Timer _debounceTimer;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _containerHeight = Tween<double>(
        begin: 48,//By R
        end: 250)
        .animate(
      CurvedAnimation(
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
        parent: _animationController,
      ),
    );
    _listOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
        parent: _animationController,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    // padding: EdgeInsets.symmetric(horizontal: 5),//By R
    width: MediaQuery.of(context).size.width,
    child: _searchContainer(
      child: _searchInput(context),
    ),
  );

  // Widgets
  Widget _searchContainer({Widget child}) {
    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Container(
            height: _containerHeight.value,
            decoration: _containerDecoration(),
            // padding: EdgeInsets.only(left: 0, right: 0, top: 15),//By R
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                child, //By R
                // Padding(//By R
                //   padding: const EdgeInsets.symmetric(horizontal: 12.0),//By R
                //   child: child,//By R
                // ),//By R
                // SizedBox(height: 10),//By R
                Expanded(
                  child: Opacity(
                    opacity: _listOpacity.value,
                    child: ListView(
                      // addSemanticIndexes: true,
                      // itemExtent: 10,
                      children: <Widget>[
                        for (var places in _placePredictions)
                          _placeOption(places),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _searchInput(BuildContext context) {
    return Center(
      child: Row(
        children: <Widget>[
          Container(width: 15),//By R
          Expanded(
            child: TextField(
              onTap: () async {
                widget.onInputTapped();
              },
              decoration: _inputStyle(),
              controller: _textEditingController,
              style: TextStyle(
                fontSize:
                widget.fontSize ?? MediaQuery.of(context).size.width * 0.04,
              ),
              onChanged: (value) async {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(
                  Duration(milliseconds: 750),
                      () async {
                    await _autocompletePlace(value);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),
          Container(width: 15),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.black,
            icon: widget.icon,
            onPressed: () async {
              _textEditingController.clear();
              widget.onIconTapped(_textEditingController.text);
            },
          ),
          // GestureDetector(
          //   child: widget.icon,//By R
          //   onTap: () async{//By R
          //     widget.onIconTapped(_textEditingController.text);//By R
          //     // Makes animation//By R
          //     await _animationController.animateTo(0.5);//By R
          //     setState(() {//By R
          //       _placePredictions = [];//By R
          //       // _selectedPlace = prediction;//By R
          //     });//By R
          //     _animationController.reverse();//By R
          //     if (widget.popOnSelect) Navigator.pop(context);//By R
          //   },//By R
          // ),
          Container(width: 15),//By R
        ],
      ),
    );
  }

  Widget _placeOption(MapBoxPlace prediction) {
    String place = prediction.text;
    String fullName = prediction.placeName;

    return MaterialButton(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      onPressed: () => _selectPlace(prediction),
      child: ListTile(
        title: Text(
          place.length < 45
              ? "$place"
              : "${place.replaceRange(45, place.length, "")} ...",
          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
          maxLines: 1,
        ),
        subtitle: Text(
          fullName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03),
          maxLines: 1,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 0,
        ),
      ),
    );
  }

  // Styling
  InputDecoration _inputStyle() {
    return InputDecoration(
      hintText: widget.searchHint,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(8.0)), //By R//Original 6.0
      boxShadow: [
        BoxShadow(color: Colors.black, blurRadius: 0, spreadRadius: 0)
      ],
    );
  }

  // Methods
  Future _autocompletePlace(String input) async {
    /// Will be called when the input changes. Making callbacks to the Places
    /// Api and giving the user Place options
    ///
    if (input.length > 0) {
      var placesSearch = PlacesSearch(
        apiKey: widget.apiKey,
        country: widget.country,
      );

      final predictions = await placesSearch.getPlaces(
        input,
        location: widget.location,
      );

      await _animationController.animateTo(0.5);

      setState(() => _placePredictions = predictions);

      await _animationController.forward();
    } else {
      await _animationController.animateTo(0.5);
      setState(() => _placePredictions = []);
      await _animationController.reverse();
    }
  }

  void _selectPlace(MapBoxPlace prediction) async {
    /// Will be called when a user selects one of the Place options.

    FocusManager.instance.primaryFocus?.unfocus();

    // Makes animation
    await _animationController.animateTo(0.5);
    setState(() {
      _placePredictions = [];
      // _selectedPlace = prediction;
    });
    _animationController.reverse();

    // Sets TextField value to be the location selected
    _textEditingController.value = TextEditingValue(
      text: prediction.placeName,
      selection: TextSelection.collapsed(offset: prediction.placeName.length),
    );

    // Calls the `onSelected` callback
    widget.onSelected(prediction);
    if (widget.popOnSelect) Navigator.pop(context);
  }
}
