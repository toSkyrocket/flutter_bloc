import 'package:flutter_bloc/bloc.dart';

/// 可管理Subject通用的Bloc
class SubjectBloc = BaseBloc with SubjectManagerMixin, ObservableMixin;
