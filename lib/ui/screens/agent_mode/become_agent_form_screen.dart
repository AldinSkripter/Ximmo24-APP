import 'package:dio/dio.dart';
import 'package:ebroker/data/cubits/agents/apply_agent_verification_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_agent_registration_form_cubit.dart';
import 'package:ebroker/data/model/agent/agent_registration_form_section_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/widgets/user_verification_form.dart';
import 'package:flutter/material.dart';

class BecomeAgentFormScreen extends StatefulWidget {
  const BecomeAgentFormScreen({
    required this.formType,
    super.key,
  });

  final String formType;

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => FetchAgentRegistrationFormCubit(),
          ),
          BlocProvider(
            create: (_) => ApplyAgentVerificationCubit(),
          ),
        ],
        child: BecomeAgentFormScreen(
          formType: arguments?['form_type'] as String? ?? 'become_agent',
        ),
      ),
    );
  }

  @override
  State<BecomeAgentFormScreen> createState() => _BecomeAgentFormScreenState();
}

class _BecomeAgentFormScreenState extends State<BecomeAgentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};
  final Map<int, AgentDocuments> _selectedDocuments = {};
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      context
          .read<FetchAgentRegistrationFormCubit>()
          .fetchAgentRegistrationForm(
            formType: widget.formType,
          ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: CustomAppBar(
        title: 'agentRegistration'.translate(context),
      ),
      body:
          BlocBuilder<
            FetchAgentRegistrationFormCubit,
            FetchAgentRegistrationFormState
          >(
            builder: (context, state) {
              if (state is FetchAgentRegistrationFormLoading) {
                return Center(child: UiUtils.progress());
              }
              if (state is FetchAgentRegistrationFormFailure) {
                return SomethingWentWrong(
                  errorMessage: state.errorMessage,
                );
              }
              if (state is FetchAgentRegistrationFormSuccess) {
                final sections = state.sections;
                if (sections.isEmpty) {
                  return Center(
                    child: CustomText('noDataFound'.translate(context)),
                  );
                }
                return Column(
                  children: [
                    _buildStepper(context, sections),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildStepContent(context, sections),
                      ),
                    ),
                    _buildBottomButtons(context, sections),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
    );
  }

  Widget _buildStepper(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    return Container(
      color: context.color.secondaryColor,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: List.generate(sections.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? context.color.tertiaryColor
                    : context.color.borderColor,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == _currentStep;
          final isCompleted = stepIndex < _currentStep;
          return Column(
            mainAxisSize: .min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: isActive || isCompleted
                      ? context.color.tertiaryColor
                      : context.color.borderColor,
                  border: Border.all(
                    color: isActive || isCompleted
                        ? context.color.tertiaryColor
                        : context.color.borderColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: context.color.buttonColor,
                        )
                      : CustomText(
                          '${stepIndex + 1}',
                          fontSize: context.font.xs,
                          fontWeight: .w600,
                          color: isActive
                              ? context.color.buttonColor
                              : context.color.textLightColor,
                        ),
                ),
              ),
              SizedBox(height: 4.rh(context)),
              SizedBox(
                width: 60,
                child: CustomText(
                  sections[stepIndex].translatedName,
                  fontSize: context.font.xxs,
                  textAlign: .center,
                  color: isActive || isCompleted
                      ? context.color.tertiaryColor
                      : context.color.textLightColor,
                  fontWeight: isActive ? .w600 : .w400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    final section = sections[_currentStep];
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: .start,
          children: section.fields.map(_buildFormField).toList(),
        ),
      ),
    );
  }

  Widget _buildFormField(AgentRegistrationFormFieldModel field) {
    final fieldValue = _formData[field.name];
    switch (field.fieldType) {
      case 'text':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'number':
        return _buildTextField(field, fieldValue?.toString() ?? '');
      case 'radio':
        return _buildRadioGroup(field, fieldValue?.toString() ?? '');
      case 'checkbox':
        return _buildCheckboxGroup(field, fieldValue);
      case 'dropdown':
        return _buildDropdown(field, fieldValue?.toString() ?? '');
      case 'textarea':
        return _buildTextArea(field, fieldValue?.toString() ?? '');
      case 'file':
        return _buildFilePickerField(field);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTitle(String title) {
    return Row(
      children: [
        CustomText(
          title,
          fontSize: context.font.sm,
          fontWeight: .w500,
        ),
        SizedBox(width: 4.rw(context)),
        HelperUtils.requiredSymbol(context),
      ],
    );
  }

  Widget _buildFilePickerField(AgentRegistrationFormFieldModel field) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        _buildTitle(field.translatedName),
        SizedBox(height: 4.rh(context)),
        _BecomeAgentDocumentPicker(
          initialDocument: _selectedDocuments[field.id],
          title: field.translatedName,
          onDocumentSelected: (doc) {
            setState(() {
              if (doc != null) {
                _selectedDocuments[field.id] = doc;
              } else {
                _selectedDocuments.remove(field.id);
              }
            });
          },
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  Widget _buildTextField(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }
    return Column(
      crossAxisAlignment: .start,
      children: [
        _buildTitle(field.translatedName),
        SizedBox(height: 4.rh(context)),
        CustomTextFormField(
          hintText: '${'enter'.translate(context)} ${field.translatedName}',
          controller: _controllers[field.name],
          action: .next,
          validator: CustomTextFieldValidator.nullCheck,
          onChange: (value) => _formData[field.name] = value,
          keyboard: field.fieldType == 'number'
              ? TextInputType.number
              : TextInputType.text,
          formaters: field.fieldType == 'number'
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  Widget _buildTextArea(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (!_controllers.containsKey(field.name)) {
      _controllers[field.name] = TextEditingController(text: fieldValue);
    }
    return Column(
      crossAxisAlignment: .start,
      children: [
        _buildTitle(field.translatedName),
        SizedBox(height: 4.rh(context)),
        CustomTextFormField(
          hintText: '${'enter'.translate(context)} ${field.translatedName}',
          controller: _controllers[field.name],
          action: .newline,
          validator: CustomTextFieldValidator.nullCheck,
          onChange: (value) => _formData[field.name] = value,
          maxLine: 50,
          minLine: 3,
        ),
        SizedBox(height: 16.rh(context)),
      ],
    );
  }

  Widget _buildRadioGroup(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    return FormField<String>(
      initialValue: fieldValue,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${field.translatedName} ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            _buildTitle(field.translatedName),
            SizedBox(height: 4.rh(context)),
            ...field.formFieldsValues.map(
              (option) => RadioGroup<String>(
                groupValue: state.value,
                onChanged: (value) {
                  state.didChange(value);
                  _formData[field.name] = value;
                },
                child: RadioListTile(
                  radioScaleFactor: 1.1,
                  dense: true,

                  activeColor: context.color.tertiaryColor,
                  controlAffinity: .trailing,
                  title: CustomText(
                    option.translatedValue ?? option.value,
                    fontSize: context.font.sm,
                    color: state.hasError
                        ? Colors.red
                        : context.color.textLightColor,
                  ),
                  value: option.value,
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, start: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }

  Widget _buildCheckboxGroup(
    AgentRegistrationFormFieldModel field,
    dynamic fieldValue,
  ) {
    var initialValues = <String>[];
    if (fieldValue is String) {
      initialValues = fieldValue.split(',').map((e) => e.trim()).toList();
    } else if (fieldValue is List<String>) {
      initialValues = fieldValue;
    }
    return FormField<List<String>>(
      initialValue: initialValues,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${field.translatedName} ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            _buildTitle(field.translatedName),
            SizedBox(height: 4.rh(context)),
            ...field.formFieldsValues.map(
              (option) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError
                        ? Colors.red
                        : context.color.borderColor,
                  ),
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CheckboxListTile(
                  dense: true,
                  activeColor: context.color.tertiaryColor,
                  title: CustomText(
                    option.translatedValue ?? option.value,
                    fontSize: context.font.sm,
                    fontWeight: .w400,
                    color: context.color.textLightColor,
                  ),
                  value: state.value!.contains(option.value),
                  onChanged: (checked) {
                    final newValue = List<String>.from(state.value!);
                    if (checked!) {
                      newValue.add(option.value);
                    } else {
                      newValue.remove(option.value);
                    }
                    state.didChange(newValue);
                    _formData[field.name] = newValue.join(',');
                  },
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(
    AgentRegistrationFormFieldModel field,
    String? fieldValue,
  ) {
    if (field.formFieldsValues.isEmpty) return const SizedBox.shrink();
    return FormField<String>(
      initialValue: field.formFieldsValues.first.value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${field.translatedName} ${'isRequired'.translate(context)}';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: .start,
          children: [
            _buildTitle(field.translatedName),
            SizedBox(height: 4.rh(context)),
            DropdownButtonHideUnderline(
              child: Container(
                width: context.screenWidth,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError
                        ? Colors.red
                        : context.color.borderColor,
                  ),
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<String>(
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down, size: 24.rh(context)),
                  padding: const EdgeInsets.all(4),
                  borderRadius: BorderRadius.circular(4),
                  elevation: 1,
                  dropdownColor: context.color.secondaryColor,
                  isExpanded: true,
                  value: state.value,
                  items: field.formFieldsValues.map((option) {
                    return DropdownMenuItem<String>(
                      value: option.value,
                      child: CustomText(
                        option.translatedValue ?? option.value,
                        fontSize: context.font.xs,
                        color: context.color.textLightColor,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    state.didChange(value);
                    _formData[field.name] = value;
                  },
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 12),
                child: CustomText(
                  state.errorText!,
                  color: context.color.error,
                  fontSize: context.font.xs,
                ),
              ),
            SizedBox(height: 16.rh(context)),
          ],
        );
      },
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    List<AgentRegistrationFormSectionModel> sections,
  ) {
    final isLastStep = _currentStep == sections.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: context.color.secondaryColor,
      child: BlocConsumer<ApplyAgentVerificationCubit, ApplyAgentVerificationState>(
        listener: (context, state) {
          if (state is ApplyAgentVerificationSuccess) {
            unawaited(
              Navigator.pushReplacementNamed(
                context,
                Routes.agentRegistrationSuccess,
              ),
            );
          } else if (state is ApplyAgentVerificationFailure) {
            HelperUtils.showSnackBarMessage(
              context,
              '${'failedTOApplyVerification'.translate(context)}: ${state.errorMessage.translate(context)}',
              type: .error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ApplyAgentVerificationInProgress;
          return Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: UiUtils.buildButton(
                    context,
                    onPressed: () => setState(() => _currentStep--),
                    buttonTitle: 'back'.translate(context),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
              ],
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  isInProgress: isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (isLastStep) {
                        await _submitForm(sections);
                      } else {
                        setState(() => _currentStep++);
                      }
                    }
                  },
                  height: 48,
                  buttonTitle: isLastStep
                      ? 'submit'.translate(context)
                      : 'next'.translate(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm(
    List<AgentRegistrationFormSectionModel> sections,
  ) async {
    final formFields = <Map<String, dynamic>>[];
    for (final section in sections) {
      for (final field in section.fields) {
        if (field.fieldType == 'file') {
          final doc = _selectedDocuments[field.id];
          if (doc == null) {
            HelperUtils.showSnackBarMessage(
              context,
              'pleaseSelectAValidDocument',
              type: .error,
            );
            return;
          }
          if (doc.isExisting && doc.file == null) continue;
          if (doc.file != null) {
            formFields.add({
              'id': field.id.toString(),
              'value': MultipartFile.fromFileSync(
                doc.file!,
                filename: doc.name,
              ),
            });
          }
        } else if (field.fieldType == 'checkbox') {
          final value = _formData[field.name];
          if (value != null && value.toString().isNotEmpty) {
            formFields.add({
              'id': field.id.toString(),
              'value': value.toString(),
            });
          }
        } else {
          final value = _formData[field.name];
          if (value != null) {
            formFields.add({
              'id': field.id.toString(),
              'value': value.toString(),
            });
          }
        }
      }
    }
    await context.read<ApplyAgentVerificationCubit>().applyVerification(
      parameters: {'form_fields': formFields, 'form_type': 'become_agent'},
    );
  }
}

class _BecomeAgentDocumentPicker extends StatefulWidget {
  const _BecomeAgentDocumentPicker({
    required this.title,
    required this.onDocumentSelected,
    this.initialDocument,
  });
  final String title;
  final void Function(AgentDocuments?) onDocumentSelected;
  final AgentDocuments? initialDocument;

  @override
  State<_BecomeAgentDocumentPicker> createState() =>
      _BecomeAgentDocumentPickerState();
}

class _BecomeAgentDocumentPickerState
    extends State<_BecomeAgentDocumentPicker> {
  AgentDocuments? selectedDocument;

  @override
  void initState() {
    super.initState();
    selectedDocument = widget.initialDocument;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: context.color.textLightColor,
            radius: const Radius.circular(4),
          ),
          child: SizedBox(
            width: 48.rh(context),
            height: 48.rw(context),
            child: IconButton(
              onPressed: _pickDocument,
              icon: Icon(
                Icons.upload,
                color: context.color.textLightColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.rw(context)),
        Column(
          crossAxisAlignment: .start,
          children: [
            CustomText('${'uploadBtnLbl'.translate(context)} ${widget.title}'),
            SizedBox(height: 4.rh(context)),
            CustomText(
              selectedDocument != null
                  ? (selectedDocument!.isExisting
                        ? 'existingDocument'.translate(context)
                        : 'oneFileSelected'.translate(context))
                  : 'noFileSelected'.translate(context),
              color: context.color.textLightColor,
              fontSize: context.font.xs,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDocument() async {
    try {
      final file = await AppFilePicker.pickFile(
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );
      if (file != null) {
        setState(() {
          selectedDocument = AgentDocuments(name: file.name, file: file.path);
        });
        widget.onDocumentSelected(selectedDocument);
      }
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
